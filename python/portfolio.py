import datetime as dt

from abc import ABCMeta, abstractmethod
from queue import Queue

from events import FillEvent, OrderEvent, SignalEvent

class PortfolioAbstractClass(metaclass = ABCMeta):

    """Abstract base class that provides an interface for all inherited portfolio objects."""

    @abstractmethod
    def update_signal(self, event):
        pass
    
    @abstractmethod
    def update_fill(self, event):
        pass

class GammaBandsPortfolio(PortfolioAbstractClass):

    """Portfolio for the gamma bands strategy."""
    
    def __init__(self, event_queue, data, initial_capital = 1000):
        
        self.event_queue = event_queue
        self.data = data
        self.initial_capital = initial_capital
        self.all_positions = []  # historical positions
        self.current_position = {}  # active position
        self.balance = self.initial_capital
        
    def calculate_profit(self, data):

        """Calculates current positions profit."""

        position_direction = 0

        if self.current_position['Direction'] == 'BUY':
            position_direction = 1
        else:
            position_direction = -1

        profit_pips = position_direction * (data[0]['Close'] - self.current_position['Open Price']) * 10000
        profit = profit_pips * (0.0001 / data[0]['Close']) * self.current_position['Quantity']

        return round(profit, 2)
    
    def update_portfolio(self, event):
        
        """Updates current_position and portfolio balance when a MarketEvent occurs."""
        
        data = self.data.get_latest_data()
        
        if len(self.current_position) > 0:
            self.balance -= self.current_position['Profit']
            profit = self.calculate_profit(data)
            self.current_position['Profit'] = profit
            self.balance += self.current_position['Profit']
    
    def update_position_from_fill(self, event):
        
        """Takes a FillEvent from the broker and adds or removes current_position."""
        
        data = self.data.get_latest_data()

        if event.order_type == 'EXIT':
            position_summary = {
                'Direction': self.current_position['Direction'],
                'Quantity': self.current_position['Quantity'],
                'Symbol': self.current_position['Symbol'],
                'Open Time': self.current_position['Open Time'],
                'Open Price': self.current_position['Open Price'],
                'SL': self.current_position['SL'],
                'Close Time': event.datestamp.strftime('%d-%m-%Y %H:%M:%S'),
                'Close Price': data[0]['Close'],  # filled on bar close
                'Profit': self.current_position['Profit']
            }
            self.all_positions.append(position_summary)
            
            # remove current_position
            self.current_position.clear()
        else:
            # add current_position
            self.current_position['Open Time'] = event.datestamp.strftime('%d-%m-%Y %H:%M:%S')
            self.current_position['Direction'] = event.direction
            self.current_position['Quantity'] = event.quantity
            self.current_position['Symbol'] = event.symbol
            self.current_position['Open Price'] = data[0]['Close']  # filled on bar close
            self.current_position['SL'] = (
                data[0]['Close'] - 0.0020 if event.direction == 'BUY' else data[0]['Close'] + 0.0020
            )
            self.current_position['Profit'] = 0
        
    def update_fill(self, event):

        """Receives a FillEvent and updates the current_position."""
        
        if isinstance(event, FillEvent):
            self.update_position_from_fill(event)
    
    def generate_order(self, event):

        """Receives a SignalEvent from the strategy and generates an OrderEvent."""
                
        symbol = event.symbol
        datestamp = event.datestamp
        signal_type = event.signal_type
        direction = event.direction
        
        mkt_quantity = 1000  # units not lots
        
        order = OrderEvent(symbol, datestamp, signal_type, mkt_quantity, direction)
        
        return(order)

    def update_signal(self, event):

        """Receives a SignalEvent and creates an OrderEvent."""
            
        if isinstance(event, SignalEvent):
            order = self.generate_order(event)
            self.event_queue.put(order)
