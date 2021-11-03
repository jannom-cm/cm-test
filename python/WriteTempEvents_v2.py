#! /usr/bin/python3
import time, os, json, configparser
import requests
import logging
from prometheus_client import start_http_server, Gauge, Summary
import random


class WriteTempEvents():
    def __init__(self, conf_file, conf_section):
        self.config = configparser.ConfigParser()
        self.config.read(conf_file)
        self.api_uri  = self.config[conf_section]["api_uri"]
        self.api_key  = self.config[conf_section]["api_key"]
        self.api_town = self.config[conf_section]["api_town"]    
        self.api_unit = self.config[conf_section]["api_unit"]
        self.sleep_time_seconds   =  int(self.config[conf_section]["sleep_time_seconds"])
        logging.basicConfig(filename=self.config[conf_section]["log_file"], 
                            filemode='a', 
                            level=int(self.config[conf_section]["log_level"]),
                            format='%(asctime)s %(levelname)s %(message)s', 
                            datefmt='%Y-%m-%dT%H:%M:%S')

    ########################################################################
    def start(self):

        weather_gauge = Gauge('janno_weather_requests', 'Description of gauge')
        formated_uri =  self.get_uri_with_values(self.api_uri,self.api_town,self.api_key,self.api_unit)
        print ("api uri: ",formated_uri)
        start_http_server(8000)
        while True:
            api_response = self.get_api_response(formated_uri)
            print ("api response: ", api_response)
            temp=self.get_temp_and_write_result_to_log(api_response)
            weather_gauge.set(temp)
            time.sleep(self.sleep_time_seconds)

    ########################################################################
    def get_uri_with_values(self,uri_template,town,key,unit):

        return uri_template.format(
                town=town,
                key=key,
                unit=unit
                )

    def get_api_response(self,formated_uri):    

          response = requests.get(formated_uri)
          return response


    def get_temp_and_write_result_to_log(self,api_response):

        if (api_response.status_code == 200):
               response_to_json = api_response.json()
               #print(json.dumps(), indent=2))
               print("-----------------------------------")
               temp=response_to_json['main']['temp'] #loaded_json = json.dumps(api_response.json())
               #print (response_to_json['main']['temp'])                       
               logging.info("%s temp: %s" % (self.api_town,temp))
        else:
               logging.warning("API response: %s" % api_response.status_code)

        return temp

if __name__ == '__main__':
        events = WriteTempEvents('WriteTempEvents.cfg', 'main')
        events.start()
