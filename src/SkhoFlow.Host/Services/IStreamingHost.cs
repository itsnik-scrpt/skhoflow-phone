using SkhoFlow.Host.Models;
using System;
using System.Threading.Tasks;

namespace SkhoFlow.Host.Services;

public interface IStreamingHost
{
    bool IsActive { get; }
    SessionStats? CurrentStats { get; }

    event EventHandler<SessionStats>? StatsUpdated;
    event EventHandler<string>? StateChanged;

    Task StartAsync(PairedDevice device, StreamSettings settings);
    Task StopAsync();
}
