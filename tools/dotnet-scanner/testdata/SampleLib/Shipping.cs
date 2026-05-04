namespace SampleLib.Shipping;

public interface IShippingService
{
    Task<ShipmentResult> Ship(Guid orderId);
}

public sealed class ShippingService : IShippingService
{
    public ShippingService(
        IShippingService inner,
        IOrderRepository orderRepo,
        IInventoryService inventory,
        INotificationService notifications,
        IRateCalculator rates,
        IAddressValidator addresses,
        ITrackingProvider tracking)
    { }

    public Task<ShipmentResult> Ship(Guid orderId) => throw new NotImplementedException();
}

public interface IOrderRepository { }
public interface IInventoryService { }
public interface INotificationService { }
public interface IRateCalculator { }
public interface IAddressValidator { }
public interface ITrackingProvider { }

public record ShipmentResult(Guid ShipmentId, string TrackingNumber);
