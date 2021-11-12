# cm-test
cm-testtöö




Sometimes, after the pinger work nice for many days and Grafa has nice picture, it stops and in python log, there is an error:

requests.exceptions.ConnectionError: HTTPSConnectionPool(host='api.openweathermap.org', port=443): 
Max retries exceeded with url: /data/2.5/weather?q=Tallinn&APPID=8391900b395251da6a1a991afef23635&units=metric 
(Caused by NewConnectionError('<urllib3.connection.VerifiedHTTPSConnection object at 0x7f7ffc4c26d0>: 
Failed to establish a new connection: [Errno 110] Connection timed out'))

so, for the app to be more robust, instead of just one thread of python running in the background, an improvement would be if there is some retry logic
 or jsut a simple exception-catching block :)


