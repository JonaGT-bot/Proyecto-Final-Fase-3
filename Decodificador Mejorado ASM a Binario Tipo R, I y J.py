import tkinter as tk
from tkinter import filedialog, messagebox
import os

def decodificar_instruccion(linea):
    partes = [p.strip() for p in linea.strip().split(',')]

    if not partes:
        return ""

    instruccion = partes[0].upper()

    # Diccionarios
    tipo_r_funct = {
        'ADD': '100000',
        'SUB': '100010',
        'SLT': '101010',
        'AND': '100100',
        'OR': '100101'
    }

    tipo_i_opcodes = {
        "SW": "101011",
        "LW": "100011",
        "BEQ": "000100",
        "BNE": "000101",
        "SLTI": "001010",
        "BGTZ": "000111",
        "ANDI": "001100",
        "ORI": "001101",
        "ADDI": "001000"
    }

    tipo_j_opcode = '000010'

    def a_bin(numero_str, bits):
        num = int(numero_str)
        binario = format(num, f'0{bits}b')
        if len(binario) > bits:
            raise ValueError(f"{numero_str} no cabe en {bits} bits")
        return binario

    if instruccion == 'NOP':
        return '\n'.join(['00000000'] * 4)

    if instruccion in tipo_r_funct:
        if len(partes) != 4:
            raise ValueError(f"Instrucción R mal formada: {linea}")

        opcode = '000000'
        rd = a_bin(partes[1].replace('$', ''), 5)
        rs = a_bin(partes[2].replace('$', ''), 5)
        rt = a_bin(partes[3].replace('$', ''), 5)
        shamt = '00000'
        funct = tipo_r_funct[instruccion]

        instruccion_bin = opcode + rs + rt + rd + shamt + funct

    elif instruccion in tipo_i_opcodes:
        if len(partes) != 4:
            raise ValueError(f"Instrucción I mal formada: {linea}")

        opcode = tipo_i_opcodes[instruccion]
        rs = a_bin(partes[1].replace('$', ''), 5)
        rt = a_bin(partes[2].replace('$', ''), 5)
        inmediato = a_bin(partes[3].replace('#', ''), 16)

        instruccion_bin = opcode + rs + rt + inmediato

    elif instruccion == 'J':
        if len(partes) != 2:
            raise ValueError(f"Instrucción J mal formada: {linea}")

        opcode = tipo_j_opcode
        direccion = a_bin(partes[1].replace('#', ''), 26)
        instruccion_bin = opcode + direccion

    else:
        raise ValueError(f"Instrucción desconocida: {linea}")

    segmentos = '\n'.join([instruccion_bin[i:i+8] for i in range(0, 32, 8)])
    return segmentos

def procesar_archivo(archivo_asm, archivo_txt):
    with open(archivo_asm, 'r', encoding='utf-8') as f:
        lineas = f.readlines()

    instrucciones = []
    errores = []

    for num, linea in enumerate(lineas, start=1):
        if not linea.strip() or linea.strip().startswith('#'):
            continue
        try:
            bin_instr = decodificar_instruccion(linea)
            instrucciones.append(bin_instr)
        except Exception as e:
            errores.append(f"Línea {num}: {e}")

    with open(archivo_txt, 'w', encoding='utf-8') as f:
        f.write('\n'.join(instrucciones))

    if errores:
        messagebox.showwarning("Completado con errores", "\n".join(errores))
    else:
        messagebox.showinfo("Listo", "Instrucciones convertidas correctamente.")

def seleccionar_archivo():
    archivo_asm = filedialog.askopenfilename(
        title="Selecciona archivo .asm",
        filetypes=(("Archivos ASM", "*.asm"),)
    )
    if archivo_asm:
        archivo_txt = os.path.splitext(archivo_asm)[0] + "_binario.txt"
        procesar_archivo(archivo_asm, archivo_txt)
        messagebox.showinfo("Guardado", f"Archivo guardado en:\n{archivo_txt}")

def crear_interfaz():
    ventana = tk.Tk()
    ventana.title("Decodificador de Instrucciones R, I y J")
    ventana.geometry("400x150")

    label = tk.Label(ventana, text="Selecciona un archivo .asm para convertir:")
    label.pack(pady=10)

    btn = tk.Button(ventana, text="Seleccionar Archivo", command=seleccionar_archivo)
    btn.pack(pady=10)

    ventana.mainloop()

if __name__ == "__main__":
    crear_interfaz()
