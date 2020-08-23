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
    
    def __init__(self, portfolio, event_queue):
        self.portfolio = portfolio
        self.symbol = 'EURUSD'
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

        data = self.portfolio.data.get_latest_data(10)
        below_band = 0

        for i, bar in enumerate(data):
            if i != (len(data) - 1):  # ignore the latest bar
                if bar['Close'] < bar['lb']:
                    below_band += 1
            else:
                continue

        return below_band

    def bars_over_ub(self):

        """Counts how many bars closed above upper band."""

        data = self.portfolio.data.get_latest_data(10)
        above_band = 0

        for i, bar in enumerate(data):
            if i != (len(data) - 1):  # ignore the latest bar
                if bar['Close'] > bar['ub']:
                    above_band += 1
            else:
                continue
        
        return above_band
    
    def check_for_open(self, data):

        """Checks to see if a position should be opened."""

        datestamp = dt.datetime.strptime(data[0]['Time'], '%d-%m-%Y %H:%M:%S')

        if not self.active_long and not self.active_short:
            # open buy conditions
            if (self.bars_under_lb() < 1) & (data[0]['Low'] <= data[0]['lb']):
                signal = SignalEvent(self.symbol, datestamp, 'LONG', 'BUY')
                self.event_queue.put(signal)
                self.active_long = True
                            
            # open sell conditions
            elif (self.bars_over_ub() < 1) & (data[0]['High'] >= data[0]['ub']):
                signal = SignalEvent(self.symbol, datestamp, 'SHORT', 'SELL')
                self.event_queue.put(signal)
                self.active_short = True
    
    def check_for_sl(self, position, data):

        """Checks to see if position stop loss hit."""

        datestamp = dt.datetime.strptime(data[0]['Time'], '%d-%m-%Y %H:%M:%S')
        buy_sl = position['Open Price'] - 0.0020  # fixed 20 pip sl
        sell_sl = position['Open Price'] + 0.0020  # fixed 20 pip sl

        # active buy stop loss conditions
        if self.active_long & (data[0]['Low'] <= buy_sl):
            signal = SignalEvent(self.symbol, datestamp, 'EXIT', 'SELL')
            self.event_queue.put(signal)
            self.active_long = False
                            
        # active sell stop loss conditions
        elif self.active_short & (data[0]['High'] >= sell_sl):
            signal = SignalEvent(self.symbol, datestamp, 'EXIT', 'BUY')
            self.event_queue.put(signal)
            self.active_short = False

    def check_for_tp(self, data):

        """Checks to see if position take profit hit."""

        datestamp = dt.datetime.strptime(data[0]['Time'], '%d-%m-%Y %H:%M:%S')

        # active buy take profit conditions
        if self.active_long & (data[0]['High'] >= data[0]['vwap']):
            signal = SignalEvent(self.symbol, datestamp, 'EXIT', 'SELL')
            self.event_queue.put(signal)
            self.active_long = False
                            
        # active sell take profit conditions
        elif self.active_short & (data[0]['Low'] <= data[0]['vwap']):
            signal = SignalEvent(self.symbol, datestamp, 'EXIT', 'BUY')
            self.event_queue.put(signal)
            self.active_short = False

    def check_for_close(self, data):

        """Checks to see if a position should be closed."""

        position = self.portfolio.current_position

        if position is not None and len(position) > 0:
            self.check_for_sl(position, data)
            self.check_for_tp(data)

    def close_all_positions(self, data):

        """Closes all open positions without any checks."""

        datestamp = dt.datetime.strptime(data[0]['Time'], '%d-%m-%Y %H:%M:%S')

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
            data = self.portfolio.data.get_latest_data()

            if data is not None and len(data) > 0:
                if self.time_in_range(data):
                    self.check_for_open(data)
                    self.check_for_close(data)
                else:
                    self.close_all_positions(data)
