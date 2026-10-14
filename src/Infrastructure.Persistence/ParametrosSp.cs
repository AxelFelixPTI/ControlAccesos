// ============================================================
// Archivo  : ParametrosSp.cs
// Ruta     : Infrastructure.Persistence/
// Módulo   : ControlAccesos
// Hito     : 1 — Catálogos del módulo
// Fase     : 4 — Repository (base compartida)
// Entidad  : Compartido — acceso a datos
// Versión  : V1.0 — 2026-10-13
// Sistema  : ControlAccesos (piloto PostgreSQL, destino SAP HANA)
// ============================================================
// Lista ORDENADA de parámetros de ENTRADA de una rutina. El orden es el de la firma de la rutina:
// el ejecutor los pasa por posición y deja que los INOUT usen su DEFAULT NULL.
// ============================================================

using System.Data;

namespace Infrastructure.Persistence;

public sealed class ParametrosSp
{
    private readonly List<(string Nombre, DbType Tipo, object? Valor)> _items = new();

    public IReadOnlyList<(string Nombre, DbType Tipo, object? Valor)> Items => _items;

    public ParametrosSp Agregar(string nombre, DbType tipo, object? valor)
    {
        _items.Add((nombre, tipo, valor));
        return this;
    }
}
