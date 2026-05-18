using Microsoft.UI.Xaml;
using SkhoFlow.Host.Services;
using System;

namespace SkhoFlow.Host;

public partial class App : Application
{
    public static MainWindow? MainWindow { get; private set; }
    public static AppHost Host { get; } = new();

    public App()
    {
        InitializeComponent();
        UnhandledException += OnUnhandledException;
    }

    protected override void OnLaunched(LaunchActivatedEventArgs args)
    {
        Host.Initialize();
        MainWindow = new MainWindow();
        MainWindow.Activate();
    }

    private void OnUnhandledException(object sender, Microsoft.UI.Xaml.UnhandledExceptionEventArgs e)
    {
        System.Diagnostics.Debug.WriteLine($"[SkhoFlow] Unhandled: {e.Exception}");
        e.Handled = true;
    }
}
