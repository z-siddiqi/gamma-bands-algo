import os
import time
import datetime as dt

from queue import Queue

from events import MarketEvent, SignalEvent, OrderEvent, FillEvent
from data_source import SimulatedDataSource
from strategy import GammaBandsStrategy
from portfolio import GammaBandsPortfolio
from execution import SimulatedExecution

event_queue = Queue()
csv_dir = os.path.dirname(os.path.realpath(__file__))
data = SimulatedDataSource(event_queue, csv_dir, 'EURUSD')
strategy = GammaBandsStrategy(data, event_queue)
portfolio = GammaBandsPortfolio(event_queue, data)
broker = SimulatedExecution(event_queue)

# this loop handles the feed of data
while True:
    if data.continue_backtest is True:
        data.update_data()
    else:
        break
    
    # this loop handles events in the queue
    while True:
        try:
            event = event_queue.get_nowait()  # gets new event
        except:
            break
        
        if event is not None:
            if isinstance(event, MarketEvent):
                print('market event')
                portfolio.update_portfolio(event)
                strategy.calculate_signals(event)   # generates signal from market data
                
            elif isinstance(event, SignalEvent):
                print('signal event')
                portfolio.update_signal(event)      # generates order from signal
                
            elif isinstance(event, OrderEvent):
                print('order event')
                broker.execute_order(event)         # executes order
            
            elif isinstance(event, FillEvent):
                print('fill event')
                portfolio.update_fill(event)        # fills order

    print('one step')
    time.sleep(1)
