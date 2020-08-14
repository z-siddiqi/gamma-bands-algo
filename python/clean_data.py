import os
import pandas as pd
import datetime as dt

def vwap_bands(vwap, offset):

    """Returns offsetted vwap value."""

    return vwap + offset

df = pd.read_csv('EURUSD_Candlestick_1_M_BID_03.08.2020-07.08.2020.csv', parse_dates=[0], dayfirst=True)
df['Local time'] = df['Local time'].dt.tz_localize(None)  # remove timezone
df = df.set_index('Local time')

start_date = dt.datetime.strptime('2020-08-04 22:00:00', '%Y-%m-%d %H:%M:%S')
end_date = dt.datetime.strptime('2020-08-05 23:59:00', '%Y-%m-%d %H:%M:%S')
df = df.loc[start_date : end_date]  # grab rows between these dates

df['AvgPrice'] = (df['High'] + df['Low'] + df['Close']) / 3
df['vwap'] = (df['AvgPrice'] * df['Volume']).groupby(df.index.date).cumsum() / df['Volume'].groupby(df.index.date).cumsum()  # need to check if this is accurate
df['ub'] = vwap_bands(df['vwap'], 0.00300)
df['lb'] = vwap_bands(df['vwap'], -0.00300)

df = df.round(5)

df.to_csv('EURUSD.csv')
