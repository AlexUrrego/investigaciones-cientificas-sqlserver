"""Gestión de investigaciones científicas sobre SQL Server.

Se conecta a la base de datos InvestigacionesCientificas con pyodbc y ofrece
un menú para consultar, insertar, actualizar y eliminar investigaciones.

La conexión se configura con variables de entorno (opcionales):
    DB_SERVER  servidor o instancia   (por defecto: localhost\\SQLEXPRESS)
    DB_NAME    nombre de la base      (por defecto: InvestigacionesCientificas)
    DB_DRIVER  driver ODBC            (por defecto: ODBC Driver 18 for SQL Server)
"""

import datetime
import logging
import os

import pyodbc

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

SERVIDOR = os.getenv("DB_SERVER", r"localhost\SQLEXPRESS")
BASE_DATOS = os.getenv("DB_NAME", "InvestigacionesCientificas")
DRIVER = os.getenv("DB_DRIVER", "ODBC Driver 18 for SQL Server")
LARGO_MAXIMO = 45  # largo máximo de cada celda al imprimir tablas


# ---------- Conexión y utilidades ----------

def obtener_conexion():
    """Abre la conexión con autenticación de Windows y sin autocommit."""
    cadena = (
        f"DRIVER={{{DRIVER}}};"
        f"SERVER={SERVIDOR};"
        f"DATABASE={BASE_DATOS};"
        "Trusted_Connection=yes;"
        "Encrypt=no;"
        "TrustServerCertificate=yes;"
    )
    return pyodbc.connect(cadena, autocommit=False)


def imprimir_tabla(cursor):
    """Imprime el resultado de la última consulta como una tabla alineada."""
    if cursor.description is None:
        return
    columnas = [c[0] for c in cursor.description]
    filas = []
    for fila in cursor.fetchall():
        celdas = []
        for valor in fila:
            texto = "" if valor is None else str(valor)
            if len(texto) > LARGO_MAXIMO:
                texto = texto[:LARGO_MAXIMO - 3] + "..."
            celdas.append(texto)
        filas.append(celdas)
    if not filas:
        print("(sin resultados)")
        return
    anchos = [max(len(col), *(len(f[i]) for f in filas)) for i, col in enumerate(columnas)]
    print(" | ".join(col.ljust(anchos[i]) for i, col in enumerate(columnas)))
    print("-+-".join("-" * ancho for ancho in anchos))
    for fila in filas:
        print(" | ".join(celda.ljust(anchos[i]) for i, celda in enumerate(fila)))


def consultar(cursor, titulo, sql, parametros=()):
    """Ejecuta una consulta SELECT e imprime el resultado."""
    print(f"\n=== {titulo} ===")
    cursor.execute(sql, parametros)
    imprimir_tabla(cursor)


def pedir_entero(mensaje):
    """Pide un número entero y repite hasta que sea válido."""
    while True:
        try:
            return int(input(mensaje))
        except ValueError:
            print("Valor no válido. Ingrese un número entero.")


def pedir_fecha(mensaje):
    """Pide una fecha AAAA-MM-DD y la devuelve como datetime."""
    while True:
        try:
            fecha = datetime.datetime.strptime(input(mensaje).strip(), "%Y-%m-%d")
            return fecha
        except ValueError:
            print("Fecha no válida. Use el formato AAAA-MM-DD.")


# ---------- Consultas ----------

def mostrar_investigaciones(cursor):
    consultar(cursor, "Investigaciones", """
        SELECT i.id_investigacion AS id, i.titulo, inst.nombre AS institucion,
               a.nombre AS area, i.fecha
        FROM Investigaciones i
        JOIN Instituciones inst ON i.id_institucion = inst.id_institucion
        JOIN AreasTematicas a   ON i.id_area = a.id_area
        ORDER BY i.fecha DESC
    """)


def mostrar_autores_investigacion(cursor):
    consultar(cursor, "Autores por investigación", """
        SELECT inv.titulo AS investigacion, aut.nombre AS autor, aut.email
        FROM Investigaciones inv
        JOIN Autor_Investigacion ai ON inv.id_investigacion = ai.id_investigacion
        JOIN Autores aut            ON ai.id_autor = aut.id_autor
        ORDER BY inv.titulo, aut.nombre
    """)


def mostrar_publicaciones(cursor):
    consultar(cursor, "Publicaciones", """
        SELECT pub.id_publicacion AS id, pub.titulo AS publicacion,
               pub.fecha_publicacion, inv.titulo AS investigacion
        FROM Publicaciones pub
        JOIN Investigaciones inv ON pub.id_investigacion = inv.id_investigacion
        ORDER BY pub.fecha_publicacion
    """)


def investigaciones_por_autor(cursor):
    nombre = input("Nombre exacto del autor: ").strip()
    consultar(cursor, f"Investigaciones de {nombre}", """
        SELECT aut.nombre AS autor, inv.titulo, inv.fecha
        FROM Autores aut
        JOIN Autor_Investigacion ai ON aut.id_autor = ai.id_autor
        JOIN Investigaciones inv    ON ai.id_investigacion = inv.id_investigacion
        WHERE aut.nombre = ?
    """, (nombre,))


def resumen_por_area(cursor):
    consultar(cursor, "Investigaciones por área", """
        SELECT a.nombre AS area, COUNT(i.id_investigacion) AS total
        FROM AreasTematicas a
        LEFT JOIN Investigaciones i ON a.id_area = i.id_area
        GROUP BY a.nombre
        ORDER BY total DESC
    """)


# ---------- Modificaciones (con commit y rollback) ----------

def insertar_investigacion(conexion, cursor):
    consultar(cursor, "Instituciones disponibles",
              "SELECT id_institucion AS id, nombre FROM Instituciones")
    consultar(cursor, "Áreas disponibles",
              "SELECT id_area AS id, nombre FROM AreasTematicas")

    titulo = input("\nTítulo: ").strip()
    if not titulo:
        print("El título no puede estar vacío.")
        return
    resumen = input("Resumen: ").strip()
    fecha = pedir_fecha("Fecha (AAAA-MM-DD): ")
    id_institucion = pedir_entero("ID de la institución: ")
    id_area = pedir_entero("ID del área: ")
    palabras_clave = input("Palabras clave (separadas por coma): ").strip()

    try:
        cursor.execute("""
            INSERT INTO Investigaciones
                (titulo, resumen, fecha, id_institucion, id_area, palabras_clave)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (titulo, resumen, fecha, id_institucion, id_area, palabras_clave))
        conexion.commit()
        print("Investigación insertada.")
    except pyodbc.Error as error:
        conexion.rollback()
        logging.error("No se pudo insertar (revise los IDs): %s", error)


def actualizar_titulo(conexion, cursor):
    id_investigacion = pedir_entero("ID de la investigación: ")
    nuevo_titulo = input("Nuevo título: ").strip()
    if not nuevo_titulo:
        print("El título no puede estar vacío.")
        return
    try:
        cursor.execute(
            "UPDATE Investigaciones SET titulo = ? WHERE id_investigacion = ?",
            (nuevo_titulo, id_investigacion))
        if cursor.rowcount == 0:
            conexion.rollback()
            print("No existe una investigación con ese ID.")
        else:
            conexion.commit()
            print("Título actualizado.")
    except pyodbc.Error as error:
        conexion.rollback()
        logging.error("No se pudo actualizar: %s", error)


def eliminar_investigacion(conexion, cursor):
    id_investigacion = pedir_entero("ID de la investigación a eliminar: ")
    confirmacion = input(
        "Se eliminarán también sus autores asociados y publicaciones. Escriba SI para confirmar: ")
    if confirmacion.strip().upper() != "SI":
        print("Operación cancelada.")
        return
    try:
        cursor.execute(
            "DELETE FROM Investigaciones WHERE id_investigacion = ?", (id_investigacion,))
        if cursor.rowcount == 0:
            conexion.rollback()
            print("No existe una investigación con ese ID.")
        else:
            conexion.commit()
            print("Investigación eliminada.")
    except pyodbc.Error as error:
        conexion.rollback()
        logging.error("No se pudo eliminar: %s", error)


# ---------- Menú ----------

def menu():
    print("\n--- INVESTIGACIONES CIENTÍFICAS ---")
    print("1. Ver investigaciones")
    print("2. Ver autores por investigación")
    print("3. Ver publicaciones")
    print("4. Investigaciones de un autor")
    print("5. Resumen por área")
    print("6. Insertar investigación")
    print("7. Actualizar título")
    print("8. Eliminar investigación")
    print("9. Salir")


def main():
    try:
        conexion = obtener_conexion()
    except pyodbc.Error as error:
        logging.error("No se pudo conectar a %s / %s: %s", SERVIDOR, BASE_DATOS, error)
        return

    cursor = conexion.cursor()
    try:
        while True:
            menu()
            opcion = input("Seleccione una opción: ").strip()
            if opcion == "1":
                mostrar_investigaciones(cursor)
            elif opcion == "2":
                mostrar_autores_investigacion(cursor)
            elif opcion == "3":
                mostrar_publicaciones(cursor)
            elif opcion == "4":
                investigaciones_por_autor(cursor)
            elif opcion == "5":
                resumen_por_area(cursor)
            elif opcion == "6":
                insertar_investigacion(conexion, cursor)
            elif opcion == "7":
                actualizar_titulo(conexion, cursor)
            elif opcion == "8":
                eliminar_investigacion(conexion, cursor)
            elif opcion == "9":
                print("Saliendo del sistema...")
                break
            else:
                print("Opción no válida.")
    finally:
        cursor.close()
        conexion.close()


if __name__ == "__main__":
    main()
