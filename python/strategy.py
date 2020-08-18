import datetime as dt

from abc import ABCMeta, abstractmethod
from queue import Queue

from events import MarketEvent, SignalEvent

class StrategyAbstractClass(metaclass = ABCMeta):

    """Abstract base class that provides an interface for all inherited strategy objects."""
    
    @abstractmethod
    def calculate_signals(self):
        pass

class GammaBandsStrategy(StrategyAbstractClass):

    """VWAP and options flow based strategy."""
    
    def __init__(self, data, event_queue):
        self.data = data
        self.symbol = self.data.symbol
        self.event_queue = event_queue
        self.active_long = False
        self.active_short = False

    def time_in_range(self, data):

        """Checks to see if time is in given range."""

        time = dt.datetime.strptime(data[0]['Time'], '%d-%m-%Y %H:%M:%S').time()

        # algo should run between these two times
        start_time = dt.datetime.strptime('08:00:00', '%H:%M:%S').time()
        end_time = dt.datetime.strptime('17:00:00', '%H:%M:%S').time()

        if time >= start_time and time <= end_time:
            return True
        else:
            return False
    
    def bars_under_lb(self):

        """Counts how many bars closed below lower band."""

        data = self.data.get_latest_data(10)
        below_band = 0

        for i, bar in enumerate(data):
            if i > 0:  # ignore the first bar
                if bar['Close'] < bar['lb']:
                    below_band += 1
            else:
                continue

        return below_band

    def bars_over_ub(self):

        """Counts how many bars closed above upper band."""

        data = self.data.get_latest_data(10)
        above_band = 0

        for i, bar in enumerate(data):
            if i > 0:  # ignore the first bar
                if bar['Close'] > bar['ub']:
                    above_band += 1
            else:
                continue
        
        return above_band

    def check_for_open(self, data):

        """Checks to see if a position should be opened."""

        datestamp = dt.datetime.strptime(data[0]['Time'], '%d-%m-%Y %H:%M:%S')

        # open buy conditions
        if (self.bars_under_lb() < 1) & (data[0]['Low'] < data[0]['lb']):
            signal = SignalEvent(self.symbol, datestamp, 'LONG', 'BUY')
            self.event_queue.put(signal)
            self.active_long = True
                        
        # open sell conditions
        elif (self.bars_over_ub() < 1) & (data[0]['High'] > data[0]['ub']):
            signal = SignalEvent(self.symbol, datestamp, 'SHORT', 'SELL')
            self.event_queue.put(signal)
            self.active_short = True

    def check_for_close(self, data):

        """Checks to see if a position should be closed."""

        datestamp = dt.datetime.strptime(data[0]['Time'], '%d-%m-%Y %H:%M:%S')

        # active buy take profit conditions
        if self.active_long & (data[0]['High'] > data[0]['vwap']):
            signal = SignalEvent(self.symbol, datestamp, 'EXIT', 'SELL')
            self.event_queue.put(signal)
            self.active_long = False
                        
        # active sell take profit conditions
        elif self.active_short & (data[0]['Low'] < data[0]['vwap']):
            signal = SignalEvent(self.symbol, datestamp, 'EXIT', 'BUY')
            self.event_queue.put(signal)
            self.active_short = False
    
    def close_all_positions(self):

        """Closes all open positions."""

        # close active buy
        if self.active_long:
            signal = SignalEvent(self.symbol, datestamp, 'EXIT', 'SELL')
            self.event_queue.put(signal)
            self.active_long = False
                        
        # close active sell
        elif self.active_short:
            signal = SignalEvent(self.symbol, datestamp, 'EXIT', 'BUY')
            self.event_queue.put(signal)
            self.active_short = False

    def calculate_signals(self, event):

        """Generates the signal on each MarketEvent."""

        if isinstance(event, MarketEvent):
            data = self.data.get_latest_data()
            if data is not None and len(data) > 0:
                if self.time_in_range(data):
                    if self.active_long or self.active_short:
                        self.check_for_close(data)

                    else:  # no active positions
                        self.check_for_open(data)

                else:  # time not in range
                    self.close_all_positions()
