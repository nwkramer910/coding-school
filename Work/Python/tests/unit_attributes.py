import logging
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s -  %(levelname)s -  %(message)s')

logging.debug('Start of program')

unit_attributes = {'position': ['55N, 45E', '50N, 40E'], 'name': '51st CAA', 'subordinate_elements': 5}

subordinate_units = ['41st TD', '90th TD', '60th MRB']
aors = ['Dobropillya', 'Pokrovsk']

def unit_locator():
    logging.debug('Possible unit locations.')
    for one in subordinate_units:
        
        for two in aors:
            logging.debug(str(one))
            print(one, 'could be in the', two, 'direction.')
    
    
unit_locator()
logging.debug('End of Program.')