#! /usr/bin/python3
import time, os, json, configparser
import requests
import logging

class WriteTempEvents():
    def __init__(self, conf_file, conf_section):
        self.config = configparser.ConfigParser()
        self.config.read(conf_file)
        self.api_uri  = self.config[conf_section]["api_uri"]
        self.api_key  = self.config[conf_section]["api_key"]
        self.api_town = self.config[conf_section]["api_town"]    
        self.api_unit = self.config[conf_section]["api_unit"]
        logging.basicConfig(filename=self.config[conf_section]["log_file"], 
                            filemode='a', 
                            level=int(self.config[conf_section]["log_level"]),
                            format='%(asctime)s %(levelname)s %(message)s', 
                            datefmt='%Y-%m-%dT%H:%M:%S')

    ########################################################################
    def start(self):

        formated_uri =  self.get_uri_with_values(self.api_uri,self.api_town,self.api_key,self.api_unit)
        print ("api uri: ",formated_uri)
        api_response = self.get_api_response(formated_uri)
        print ("api response: ", api_response)
        written_to_log=self.write_result_to_log(api_response)

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


    def write_result_to_log(self,api_response):

        if (api_response.status_code == 200):
               response_to_json = api_response.json()
               #print(json.dumps(), indent=2))
               print("-----------------------------------")
               #loaded_json = json.dumps(api_response.json())
               print (response_to_json['main']['temp'])                       
               logging.info("%s temp: %s" % (self.api_town,response_to_json['main']['temp']))
        else:
               logging.warning("API response: %s" % api_response.status_code)

        return 0 

if __name__ == '__main__':
        events = WriteTempEvents('WriteTempEvents.cfg', 'main')
        events.start()
