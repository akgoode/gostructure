namespace SampleLib.Orders;

public interface IOrderService
{
    Task<OrderResult> CreateOrder(CreateOrderRequest request);
    Task<OrderResult?> GetOrder(Guid id);
    Task<IReadOnlyList<OrderResult>> ListOrders(int page, int pageSize);
}

public sealed class OrderService : IOrderService
{
    private readonly IOrderRepository _repository;
    private readonly OrderServiceOptions _options;

    public OrderService(IOrderRepository repository, OrderServiceOptions options)
    {
        _repository = repository;
        _options = options;
    }

    public Task<OrderResult> CreateOrder(CreateOrderRequest request) => throw new NotImplementedException();
    public Task<OrderResult?> GetOrder(Guid id) => throw new NotImplementedException();
    public Task<IReadOnlyList<OrderResult>> ListOrders(int page, int pageSize) => throw new NotImplementedException();

    public Task<OrderResult> ImportOrder(
        string externalId, string source, string productId,
        int quantity, decimal price, string currency, DateTime importedAt)
        => throw new NotImplementedException();
}

public class OrderServiceOptions
{
    public int MaxOrdersPerPage { get; set; } = 50;
    public TimeSpan OrderTimeout { get; set; } = TimeSpan.FromMinutes(30);
}

public interface IOrderRepository
{
    Task<Order> Save(Order order);
    Task<Order?> FindById(Guid id);
    Task<IReadOnlyList<Order>> FindByStatus(OrderStatus status);
    Task<IReadOnlyList<Order>> FindByDateRange(DateTime from, DateTime to);
    Task<int> Count();
    Task Delete(Guid id);
}

public record CreateOrderRequest(string ProductId, int Quantity);
public record OrderResult(Guid Id, string ProductId, int Quantity, DateTime CreatedAt);
public record Order(Guid Id, string ProductId, int Quantity, DateTime CreatedAt, string Status);

public class OrderNotFoundException : Exception
{
    public Guid OrderId { get; }

    public OrderNotFoundException(Guid orderId)
        : base($"Order {orderId} not found")
    {
        OrderId = orderId;
    }

    public OrderNotFoundException(Guid orderId, Exception inner)
        : base($"Order {orderId} not found", inner)
    {
        OrderId = orderId;
    }
}

public enum OrderStatus
{
    Pending,
    Confirmed,
    Shipped,
    Delivered,
    Cancelled
}

public static class OrderConstants
{
    public const int MaxItemsPerOrder = 100;
    public static readonly TimeSpan DefaultTimeout = TimeSpan.FromMinutes(30);
    public static int MutableCounter = 0;
}
