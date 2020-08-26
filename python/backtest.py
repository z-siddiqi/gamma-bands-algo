import sys 
import os
import time
import datetime as dt
import pandas as pd

from queue import Queue

from events import MarketEvent, SignalEvent, OrderEvent, FillEvent
from data_source import SimulatedDataSource
from strategy import GammaBandsStrategy
from portfolio import GammaBandsPortfolio
from execution import SimulatedExecution


def main():
    # check the number of arguments
    if len(sys.argv) != 2:
        print(f'Error! There should be 1 args.')
        sys.exit(1)

    clean_data_file(sys.argv[1])

    event_queue = Queue()
    data = SimulatedDataSource(event_queue)
    portfolio = GammaBandsPortfolio(data, event_queue)
    strategy = GammaBandsStrategy(portfolio, event_queue)
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
                    # print('market event')
                    portfolio.update_portfolio(event)
                    strategy.calculate_signals(event)   # generates signal from market data
                    
                elif isinstance(event, SignalEvent):
                    # print('signal event')
                    portfolio.update_signal(event)      # generates order from signal
                    
                elif isinstance(event, OrderEvent):
                    # print('order event')
                    broker.execute_order(event)         # executes order
                
                elif isinstance(event, FillEvent):
                    # print('fill event')
                    portfolio.update_fill(event)        # fills order

    portfolio.create_summary()


def clean_data_file(csv_path):
    """Cleans CSV file and saves it in data folder."""

    df = pd.read_csv(csv_path, parse_dates=[0], dayfirst=True)
    df['Time'] = df['Local time'].dt.tz_localize(None)  # remove timezone
    df = df.set_index('Time')
    df = df.drop('Local time', 1)

    df = df.round(5)

    curr_dir = os.path.dirname(os.path.realpath(__file__))
    save_path = os.path.join(curr_dir, 'data/data.csv')

    df.to_csv(save_path)


if __name__ == '__main__':
    main()