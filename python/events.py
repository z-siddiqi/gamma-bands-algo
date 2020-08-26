class Event():
    """Abstract base class that provides an interface for all inherited events."""

    pass

class MarketEvent(Event):
    """Event for new market data."""

    pass

class SignalEvent(Event):
    """Event for sending a signal from the strategy to the portfolio"""
    
    def __init__(self, symbol, datestamp, signal_type, direction):
        
        self.symbol = symbol
        self.datestamp = datestamp
        self.signal_type = signal_type
        self.direction = direction

class OrderEvent(Event):
    """Event for sending an order from the portfolio to execution."""
    
    def __init__(self, symbol, datestamp, order_type, quantity, direction):
        
        self.symbol = symbol
        self.datestamp = datestamp
        self.order_type = order_type
        self.quantity = quantity
        self.direction = direction

class FillEvent(Event):
    """Event for an order getting filled by the execution."""
    
    def __init__(self, symbol, datestamp, order_type, quantity, direction):
        
        self.symbol = symbol
        self.datestamp = datestamp
        self.order_type = order_type
        self.quantity = quantity
        self.direction = direction
