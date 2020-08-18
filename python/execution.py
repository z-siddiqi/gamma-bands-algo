import datetime as dt

from abc import ABCMeta, abstractmethod
from queue import Queue

from events import FillEvent, OrderEvent

class ExecutionAbstractClass(metaclass = ABCMeta):

    """Abstract base class that provides an interface for all inherited execution objects."""
    
    @abstractmethod
    def execute_order(self, event):
        pass


class SimulatedExecution(ExecutionAbstractClass):
    
    """Converts all OrderEvents to FillEvents with no latency or slippage."""
    
    def __init__(self, event_queue):
        self.event_queue = event_queue
        
    def execute_order(self, event):

        """Receives an OrderEvent and creates a FillEvent."""
        
        if isinstance(event, OrderEvent):
            fill_event = FillEvent(
                event.symbol, event.datestamp, event.order_type, event.quantity, event.direction
            )
            
            self.event_queue.put(fill_event)
