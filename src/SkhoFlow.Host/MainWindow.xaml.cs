using Microsoft.UI;
using Microsoft.UI.Composition.SystemBackdrops;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Animation;
using SkhoFlow.Host.Pages;
using System;
using Windows.UI;
using WinUIEx;

namespace SkhoFlow.Host;

public sealed partial class MainWindow : WindowEx
{
    public MainWindow()
    {
        InitializeComponent();
        Title = "SkhoFlow";
        SystemBackdrop = new MicaBackdrop { Kind = MicaKind.BaseAlt };

        ExtendsContentIntoTitleBar = true;
        SetTitleBar(AppTitleBar);

        this.MinWidth = 1080;
        this.MinHeight = 680;

        AppWindow.TitleBar.ButtonBackgroundColor = Colors.Transparent;
        AppWindow.TitleBar.ButtonInactiveBackgroundColor = Colors.Transparent;
        AppWindow.TitleBar.ButtonForegroundColor = Colors.White;
        AppWindow.TitleBar.ButtonHoverBackgroundColor = Color.FromArgb(40, 225, 29, 42);
        AppWindow.TitleBar.ButtonPressedBackgroundColor = Color.FromArgb(60, 225, 29, 42);

        ContentFrame.Navigate(typeof(HomePage), null, new SuppressNavigationTransitionInfo());
        App.Host.HostStatusChanged += OnHostStatusChanged;
    }

    private void OnHostStatusChanged(object? sender, string status)
    {
        DispatcherQueue.TryEnqueue(() =>
        {
            StatusText.Text = status;
        });
    }

    private void NavView_SelectionChanged(NavigationView sender, NavigationViewSelectionChangedEventArgs args)
    {
        if (args.SelectedItem is not NavigationViewItem item) return;

        Type? target = (item.Tag as string) switch
        {
            "home" => typeof(HomePage),
            "devices" => typeof(DevicesPage),
            "session" => typeof(SessionPage),
            "settings" => typeof(SettingsPage),
            _ => null,
        };

        if (target == null || ContentFrame.CurrentSourcePageType == target) return;
        ContentFrame.Navigate(target, null, new DrillInNavigationTransitionInfo());
    }
}
