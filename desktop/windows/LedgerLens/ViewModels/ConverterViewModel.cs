using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using LedgerLens.Core;
using LedgerLens.Models;
using Microsoft.UI.Dispatching;

namespace LedgerLens.ViewModels;

public sealed class SelectedFile
{
    public string Path { get; init; } = "";
    public string Name => System.IO.Path.GetFileName(Path);
}

/// <summary>State + logic for the converter screen. All work is local; the UI binds to this.</summary>
public sealed class ConverterViewModel : INotifyPropertyChanged
{
    private readonly DispatcherQueue _dispatcher = DispatcherQueue.GetForCurrentThread();

    public ObservableCollection<SelectedFile> Files { get; } = new();
    public ObservableCollection<TransactionRow> Rows { get; } = new();

    private string _password = "";
    public string Password
    {
        get => _password;
        set { _password = value; OnChanged(); }
    }

    private bool _isConverting;
    public bool IsConverting
    {
        get => _isConverting;
        private set { _isConverting = value; OnChanged(); OnChanged(nameof(CanConvert)); }
    }

    private string? _errorMessage;
    public string? ErrorMessage
    {
        get => _errorMessage;
        private set { _errorMessage = value; OnChanged(); OnChanged(nameof(HasError)); }
    }
    public bool HasError => !string.IsNullOrEmpty(ErrorMessage);

    private ConversionResult? _result;
    public ConversionResult? Result
    {
        get => _result;
        private set
        {
            _result = value;
            OnChanged();
            OnChanged(nameof(HasResult));
            OnChanged(nameof(IsBatch));
            OnChanged(nameof(RowCountText));
            OnChanged(nameof(PageCountText));
            OnChanged(nameof(FileCountText));
        }
    }

    public bool HasFiles => Files.Count > 0;
    public bool CanConvert => HasFiles && !IsConverting;
    public bool HasResult => Result != null;
    public bool IsBatch => Result?.IsBatch ?? false;

    public string RowCountText => $"{Result?.Rows.Count ?? 0}";
    public string PageCountText => $"{Result?.PageCount ?? 0}";
    public string FileCountText => $"{Result?.SourceFiles.Count ?? 0}";

    // MARK: File selection

    public void AddFiles(IEnumerable<string> paths)
    {
        var added = false;
        foreach (var path in paths)
        {
            if (!path.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase)) continue;
            if (Files.Any(f => string.Equals(f.Path, path, StringComparison.OrdinalIgnoreCase))) continue;
            Files.Add(new SelectedFile { Path = path });
            added = true;
        }
        if (added) ErrorMessage = null;
        OnChanged(nameof(HasFiles));
        OnChanged(nameof(CanConvert));
    }

    public void RemoveFile(SelectedFile file)
    {
        Files.Remove(file);
        OnChanged(nameof(HasFiles));
        OnChanged(nameof(CanConvert));
    }

    public void Reset()
    {
        Files.Clear();
        Rows.Clear();
        Password = "";
        Result = null;
        ErrorMessage = null;
        OnChanged(nameof(HasFiles));
        OnChanged(nameof(CanConvert));
    }

    // MARK: Conversion

    public async Task ConvertAsync()
    {
        if (!HasFiles)
        {
            ErrorMessage = "Add at least one PDF bank statement first.";
            return;
        }

        IsConverting = true;
        ErrorMessage = null;
        Rows.Clear();
        Result = null;

        var paths = Files.Select(f => f.Path).ToList();
        var password = Password;

        try
        {
            var result = await Task.Run(() => StatementConverter.Convert(paths, password));
            Result = result;
            foreach (var row in result.Rows) Rows.Add(row);
        }
        catch (Exception ex)
        {
            ErrorMessage = ex.Message;
            Result = null;
        }
        finally
        {
            IsConverting = false;
        }
    }

    // MARK: Export helpers (the caller supplies a destination path from a save picker)

    public byte[] BuildCsv() => SpreadsheetExporter.BuildCsv(Result!.Rows, Result!.IsBatch);
    public byte[] BuildXlsx() => SpreadsheetExporter.BuildXlsx(Result!.Rows, Result!.IsBatch);
    public string SuggestedFileStem => Result?.FileStem ?? "statement";

    // MARK: INotifyPropertyChanged

    public event PropertyChangedEventHandler? PropertyChanged;

    private void OnChanged([CallerMemberName] string? name = null)
    {
        if (_dispatcher != null && !_dispatcher.HasThreadAccess)
        {
            _dispatcher.TryEnqueue(() => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name)));
        }
        else
        {
            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
        }
    }
}
