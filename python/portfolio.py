import os
import datetime as dt
import pandas as pd
import numpy as np
import mplfinance as mpf

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
    
    def __init__(self, data, event_queue, initial_capital = 1000):
        
        self.event_queue = event_queue
        self.data = data
        self.all_positions = []  # historical positions
        self.current_position = {}  # active position
        self.balance = initial_capital
        self.equity = {'datestamp': [], 'balance': []}
        
    def calculate_profit(self, data):
        """Calculates current positions profit."""

        if self.current_position['Direction'] == 'BUY':
            position_direction = 1
        else:
            position_direction = -1

        profit_pips = position_direction * (data[0]['Close'] - \
            self.current_position['Open Price']) * 10000
        profit = profit_pips * (0.0001 / data[0]['Close']) * \
            self.current_position['Quantity']

        return round(profit, 2)
    
    def update_portfolio(self, event):
        """Updates current_position and portfolio balance when a MarketEvent occurs."""
        
        data = self.data.get_latest_data()
        datestamp = dt.datetime.strptime(data[0]['Time'], '%d-%m-%Y %H:%M:%S')

        if self.current_position is not None and len(self.current_position) > 0:
            profit = self.calculate_profit(data)
            self.balance += profit - self.current_position['Profit']
            self.current_position['Profit'] = profit
        
        self.equity['datestamp'].append(datestamp)
        self.equity['balance'].append(self.balance)
    
    def update_position_from_fill(self, event):
        """Takes a FillEvent from the broker and adds or removes current_position."""
        
        data = self.data.get_latest_data()
        datestamp = event.datestamp.strftime('%d-%m-%Y %H:%M:%S')

        if event.order_type == 'EXIT':
            position_summary = {
                'Direction': self.current_position['Direction'],
                'Quantity': self.current_position['Quantity'],
                'Symbol': self.current_position['Symbol'],
                'Open Time': self.current_position['Open Time'],
                'Open Price': self.current_position['Open Price'],
                'Close Time': datestamp,
                'Close Price': data[0]['Close'],
                'Profit': self.current_position['Profit']
            }
            self.all_positions.append(position_summary)
            
            # remove current_position
            self.current_position.clear()
        else:
            # add current_position
            self.current_position['Open Time'] = datestamp
            self.current_position['Direction'] = event.direction
            self.current_position['Quantity'] = event.quantity
            self.current_position['Symbol'] = event.symbol
            self.current_position['Open Price'] = data[0]['Close']
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

    def create_summary(self):
        """Creates a csv file and image showing all positions taken."""

        # csv file
        summary = pd.DataFrame.from_dict(self.equity)
        summary = summary.set_index('datestamp')
        summary['Buy Orders'] = np.nan
        summary['Sell Orders'] = np.nan

        for trade in self.all_positions:
            open_time = dt.datetime.strptime(trade['Open Time'], '%d-%m-%Y %H:%M:%S')
            close_time = dt.datetime.strptime(trade['Close Time'], '%d-%m-%Y %H:%M:%S')

            if trade['Direction'] == 'BUY':
                summary.loc[open_time, 'Buy Orders'] = trade['Open Price']
                summary.loc[close_time, 'Sell Orders'] = trade['Close Price']
            else:
                summary.loc[open_time, 'Sell Orders'] = trade['Open Price']
                summary.loc[close_time, 'Buy Orders'] = trade['Close Price']

        curr_dir = os.path.dirname(os.path.realpath(__file__))
        save_path = os.path.join(curr_dir, 'summary')
        summary.to_csv(f'{save_path}/summary.csv')

        # image
        data = self.data.symbol_data

        plots = [
            mpf.make_addplot(
                summary['Buy Orders'], type='scatter', color='green', 
                marker='^', markersize=40
            ),
            mpf.make_addplot(
                summary['Sell Orders'], type='scatter', color='red', 
                marker='v', markersize=40
            ),
            mpf.make_addplot(summary['balance'], panel=1, color='fuchsia')
        ]

        mpf.plot(
            data, type='candlestick', figratio=(18,10), panel_ratios=(8,2), 
            addplot=plots, style='sas', savefig=f'{save_path}/summary.png', 
            tight_layout=True
        )
