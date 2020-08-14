import os
import datetime
import pandas as pd
import time

class DataSource():
    
    """Reads CSV file and feeds out data to imitate a live data stream."""
    
    def __init__(self, csv_dir, symbol):
        
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
                
    def get_latest_data(self, symbol, n=1):

        """Returns the last n rows from latest_data."""
        
        return self.latest_data[-n:]
        
    def update_data(self):

        """Pushes the latest row into latest_data."""
        
        try:
            data = next(self.data_stream)
            date_time = data[0].to_pydatetime().strftime('%m-%d-%Y %H:%M:%S')
            formatted_data = {'Time': date_time, 'Open': data[1], 'High': data[2], 'Low' : data[3], 'Close' : data[4], 'vwap' : data[7], 'ub' : data[8], 'lb' : data[9]}   
            self.latest_data.append(formatted_data)
        except:
            self.continue_backtest = False  # no data left

# testing the data stream
CSV_dir = os.path.dirname(os.path.realpath(__file__))
symbol = 'EURUSD'
data = DataSource(CSV_dir, symbol)

while True:
    data.update_data()
    latest = data.get_latest_data(symbol, 1)
    print(latest)
    time.sleep(5)
