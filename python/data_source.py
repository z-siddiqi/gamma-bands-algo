import os
import pandas as pd

from abc import ABCMeta, abstractmethod

from events import MarketEvent

class DataAbstractClass(metaclass = ABCMeta):

    """Abstract base class that provides an interface for all inherited data objects."""
    
    @abstractmethod
    def get_latest_data(self, n=1):
        pass
    
    @abstractmethod
    def update_data(self):
        pass

class SimulatedDataSource(DataAbstractClass):
    
    """Reads CSV file and feeds out data to imitate a live data stream."""
    
    def __init__(self, event_queue, csv_dir, symbol):
        
        self.event_queue = event_queue
        self.csv_dir = csv_dir
        self.symbol = symbol
        self.symbol_data = pd.DataFrame()  # df containing csv
        self.data_stream = None  # iterator that returns latest row from df
        self.latest_data = []  # list containing streaming data
        self.continue_backtest = True
        
        self.initial_symbol_data()
        
    def initial_symbol_data(self):
        
        """Opens CSV file and converts it into a DataFrame."""
        
        path = os.path.join(self.csv_dir, f'{self.symbol}.csv')
        self.symbol_data = pd.read_csv(path, parse_dates=[0], dayfirst=True, index_col=0)
        self.data_stream = self.symbol_data.itertuples()
                
    def get_latest_data(self, n=1):

        """Returns the last n rows from latest_data."""
        
        return self.latest_data[-n:]
        
    def update_data(self):

        """Pushes the latest row into latest_data."""
        
        try:
            data = next(self.data_stream)
            datestamp = data[0].to_pydatetime().strftime('%d-%m-%Y %H:%M:%S')
            formatted_data = {
                'Time': datestamp,
                'Open': data[1],
                'High': data[2],
                'Low' : data[3], 
                'Close' : data[4],
                'vwap' : data[7],
                'ub' : data[8],
                'lb' : data[9]
            }   
            self.latest_data.append(formatted_data)
            self.event_queue.put(MarketEvent())
        except:
            self.continue_backtest = False  # no data left
