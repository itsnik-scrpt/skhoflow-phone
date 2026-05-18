using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using SkhoFlow.Host.Models;
using System;
using System.Threading.Tasks;

namespace SkhoFlow.Host.Pages;

public sealed partial class DevicesPage : Page
{
    public DevicesPage()
    {
        InitializeComponent();
        Loaded += OnLoaded;
        App.Host.Pairing.DevicePaired += OnDevicePaired;
    }

    private void OnLoaded(object sender, RoutedEventArgs e) => Refresh();

    private void OnDevicePaired(object? sender, PairedDevice device)
    {
        DispatcherQueue.TryEnqueue(Refresh);
    }

    private void Refresh()
    {
        var devices = App.Host.Settings.Devices;
        DevicesList.ItemsSource = devices.ToArray();
        EmptyState.Visibility = devices.Count == 0 ? Visibility.Visible : Visibility.Collapsed;
        DevicesList.Visibility = devices.Count == 0 ? Visibility.Collapsed : Visibility.Visible;
    }

    private async void PairNew_Click(object sender, RoutedEventArgs e)
    {
        var pin = App.Host.Pairing.IssuePairingPin();
        await ShowPinDialogAsync(pin);
    }

    private void RemoveDevice_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: string id })
        {
            App.Host.Settings.RemoveDevice(id);
            Refresh();
        }
    }

    private Task ShowPinDialogAsync(string pin)
    {
        var dialog = new ContentDialog
        {
            Title = "Pairing PIN",
            Content = new TextBlock
            {
                Text = $"Enter this PIN on your iPhone:\n\n{pin}\n\nExpires in 2 minutes.",
                TextWrapping = TextWrapping.Wrap,
                FontSize = 16,
            },
            CloseButtonText = "Close",
            XamlRoot = this.XamlRoot,
        };
        return dialog.ShowAsync().AsTask();
    }
}
