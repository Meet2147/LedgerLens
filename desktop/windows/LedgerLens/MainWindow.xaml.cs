using System;
using System.Collections.Generic;
using System.Linq;
using LedgerLens.Services;
using LedgerLens.ViewModels;
using Microsoft.UI;
using Microsoft.UI.Text;
using Microsoft.Win32;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.ApplicationModel.DataTransfer;
using Windows.Graphics;
using Windows.Storage;
using Windows.Storage.Pickers;

namespace LedgerLens;

public sealed partial class MainWindow : Window
{
    private readonly ConverterViewModel _vm = new();
    private readonly LicenseService _license = new();

    public MainWindow()
    {
        InitializeComponent();
        Root.DataContext = _vm;
        ResizeToDefault();
        RefreshLicenseStatus();
        ApplyAppearance(LoadAppearance());
    }

    // MARK: - Appearance (Light / Dark / System)

    private const string RegPath = @"Software\LedgerLens";

    private static string LoadAppearance()
    {
        using var key = Registry.CurrentUser.CreateSubKey(RegPath);
        return key.GetValue("Appearance") as string ?? "System";
    }

    private static void SaveAppearance(string mode)
    {
        using var key = Registry.CurrentUser.CreateSubKey(RegPath);
        key.SetValue("Appearance", mode);
    }

    private void ApplyAppearance(string mode)
    {
        Root.RequestedTheme = mode switch
        {
            "Light" => ElementTheme.Light,
            "Dark" => ElementTheme.Dark,
            _ => ElementTheme.Default,
        };
    }

    private void RefreshLicenseStatus()
    {
        LicenseStatusText.Text = _license.PillText;
    }

    private void ResizeToDefault()
    {
        var hwnd = WinRT.Interop.WindowNative.GetWindowHandle(this);
        var windowId = Win32Interop.GetWindowIdFromWindow(hwnd);
        var appWindow = AppWindow.GetFromWindowId(windowId);
        appWindow.Resize(new SizeInt32(1180, 760));
    }

    // MARK: - File selection

    private async void Browse_Click(object sender, RoutedEventArgs e)
    {
        var picker = new FileOpenPicker
        {
            ViewMode = PickerViewMode.List,
            SuggestedStartLocation = PickerLocationId.DocumentsLibrary
        };
        picker.FileTypeFilter.Add(".pdf");
        InitializeWithWindow(picker);

        var files = await picker.PickMultipleFilesAsync();
        if (files != null && files.Count > 0)
        {
            _vm.AddFiles(files.Select(f => f.Path));
        }
    }

    private void RemoveFile_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: SelectedFile file })
        {
            _vm.RemoveFile(file);
        }
    }

    private void Clear_Click(object sender, RoutedEventArgs e) => _vm.Reset();

    // MARK: - Drag & drop

    private void DropZone_DragOver(object sender, DragEventArgs e)
    {
        if (e.DataView.Contains(StandardDataFormats.StorageItems))
        {
            e.AcceptedOperation = DataPackageOperation.Copy;
            e.DragUIOverride.Caption = "Add statements";
            e.DragUIOverride.IsCaptionVisible = true;
        }
    }

    private async void DropZone_Drop(object sender, DragEventArgs e)
    {
        if (!e.DataView.Contains(StandardDataFormats.StorageItems)) return;

        var items = await e.DataView.GetStorageItemsAsync();
        var paths = items.OfType<StorageFile>().Select(f => f.Path).ToList();
        _vm.AddFiles(paths);
    }

    // MARK: - Convert

    private async void Convert_Click(object sender, RoutedEventArgs e)
    {
        if (!_license.CanConvert)
        {
            await ShowSettingsDialog(upgradePrompt: true);
            return;
        }
        await _vm.ConvertAsync();
        if (_vm.Result != null)
        {
            _license.RegisterConversion(_vm.Result.SourceFiles.Count);
            RefreshLicenseStatus();
        }
    }

    // MARK: - Settings / Upgrade

    private async void Settings_Click(object sender, RoutedEventArgs e) => await ShowSettingsDialog(false);

    private async System.Threading.Tasks.Task ShowSettingsDialog(bool upgradePrompt)
    {
        var panel = new StackPanel { Spacing = 14, Width = 380 };

        panel.Children.Add(new TextBlock
        {
            Text = upgradePrompt ? "You've used your free statements" : _license.StatusText,
            FontSize = 16,
            FontWeight = FontWeights.Bold
        });

        // Appearance selector.
        var appearanceRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10, Margin = new Thickness(0, 4, 0, 4) };
        appearanceRow.Children.Add(new TextBlock { Text = "Appearance", VerticalAlignment = VerticalAlignment.Center });
        var appearanceCombo = new ComboBox();
        appearanceCombo.Items.Add("System");
        appearanceCombo.Items.Add("Light");
        appearanceCombo.Items.Add("Dark");
        appearanceCombo.SelectedItem = LoadAppearance();
        appearanceCombo.SelectionChanged += (_, _) =>
        {
            var mode = appearanceCombo.SelectedItem as string ?? "System";
            ApplyAppearance(mode);
            SaveAppearance(mode);
        };
        appearanceRow.Children.Add(appearanceCombo);
        panel.Children.Add(appearanceRow);

        if (!_license.IsPro)
        {
            panel.Children.Add(new TextBlock
            {
                Text = "Go Pro — unlimited conversions, batch PDFs, CSV + XLSX, 100% on-device.",
                TextWrapping = TextWrapping.Wrap,
                Opacity = 0.8
            });

            foreach (var plan in ProPlan.All)
            {
                var label = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8 };
                label.Children.Add(new TextBlock { Text = plan.Title, FontWeight = FontWeights.SemiBold });
                label.Children.Add(new TextBlock { Text = $"{plan.Price}{plan.Cadence}", Foreground = new SolidColorBrush(Colors.DodgerBlue) });
                label.Children.Add(new TextBlock { Text = plan.Tagline, Opacity = 0.6, FontSize = 12, VerticalAlignment = VerticalAlignment.Center });

                var button = new Button
                {
                    Content = label,
                    HorizontalAlignment = HorizontalAlignment.Stretch,
                    HorizontalContentAlignment = HorizontalAlignment.Left
                };
                var url = plan.CheckoutUrl;
                button.Click += (_, _) => _license.OpenCheckout(url);
                panel.Children.Add(button);
            }
        }

        panel.Children.Add(new TextBlock { Text = "Already purchased? Paste your license key:", Opacity = 0.8 });

        var keyBox = new TextBox { PlaceholderText = "License key", Text = _license.LicenseKey, IsEnabled = !_license.IsPro };
        panel.Children.Add(keyBox);

        var message = new TextBlock { Foreground = new SolidColorBrush(Colors.OrangeRed), TextWrapping = TextWrapping.Wrap };
        var activate = new Button { Content = _license.IsPro ? "Active" : "Activate", IsEnabled = !_license.IsPro };
        activate.Click += async (_, _) =>
        {
            activate.IsEnabled = false;
            try
            {
                var (ok, msg) = await _license.ActivateAsync(keyBox.Text);
                message.Text = ok ? "Activated — thank you!" : (msg ?? "That key isn't valid.");
                if (ok) { RefreshLicenseStatus(); activate.Content = "Active"; keyBox.IsEnabled = false; }
                else { activate.IsEnabled = true; }
            }
            catch (Exception ex)
            {
                message.Text = ex.Message;
                activate.IsEnabled = true;
            }
        };
        panel.Children.Add(activate);
        panel.Children.Add(message);

        var dialog = new ContentDialog
        {
            Title = "LedgerLens Pro",
            Content = panel,
            CloseButtonText = "Close",
            XamlRoot = Root.XamlRoot
        };
        await dialog.ShowAsync();
    }

    // MARK: - Export

    private async void ExportCsv_Click(object sender, RoutedEventArgs e)
    {
        await SaveAsync("CSV file", ".csv", _vm.BuildCsv);
    }

    private async void ExportXlsx_Click(object sender, RoutedEventArgs e)
    {
        await SaveAsync("Excel workbook", ".xlsx", _vm.BuildXlsx);
    }

    private async System.Threading.Tasks.Task SaveAsync(string label, string extension, Func<byte[]> build)
    {
        if (_vm.Result == null) return;

        var picker = new FileSavePicker
        {
            SuggestedStartLocation = PickerLocationId.DocumentsLibrary,
            SuggestedFileName = _vm.SuggestedFileStem
        };
        picker.FileTypeChoices.Add(label, new List<string> { extension });
        InitializeWithWindow(picker);

        var file = await picker.PickSaveFileAsync();
        if (file == null) return;

        await FileIO.WriteBytesAsync(file, build());
    }

    // MARK: - Helpers

    private void InitializeWithWindow(object target)
    {
        var hwnd = WinRT.Interop.WindowNative.GetWindowHandle(this);
        WinRT.Interop.InitializeWithWindow.Initialize(target, hwnd);
    }
}
