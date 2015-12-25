### APMaaS_param_local.sh - Begin ###
WEBSERVICE_API_LOGIN_SUFIX="API" # Dynatrace Portal Webservice API should have login in form "accountName.Login". In this context Login is SUFIX. In case your API login is "Foo.API", type here "API".

PRIVATE_PEER_NETWORK_ID=132414 # Type your Dynatrace Gomez Network ID here
PRIVATE_PEER_NETWORK_NAME=Global_PLM # Type your Dynatrace Gomez Network Name here
PLM_AGENTS_IGNORE='VE-CAR-Chaca1|CU7007059|NE00019|NES00405|CU07089|ND003|Foo' # If you have PLM Agent you wish to ignore, type its name here. Function getConfig_PlmAgents does not log but ignores data for these agents.

HTML_HEADER_TITLE='APPLICATION E2E MONITORING - SYNTHETIC WEB'
HTML_HEADER_TITLE_URL='https://portal.dynatrace.com'
HTML_HEADER_COMPANY='myCompany'
HTML_HEADER_COMPANY_URL='https://www.google.com'
HTML_TITLE_LEFT='Synthetic Web'
HTML_TITLE_RIGHT='with Dynatrace APMaaS'
HTML_SUBTITLE="${HTML_HEADER_COMPANY} Reseller child accounts and APMaaS tests"
HTML_EMAIL_ADDRESS='e2e@yahoo.com' # Used in CC when emailing local PLM support in ZAPMaaS_htmlFunctions.sh

HTML_PLM_MAP='http://mapmaker.education.nationalgeographic.com/c2T5ni73Rd5kzm' # URL to map PLM AGENTs in "Click here to see ... Agents Map"

HTML_PLM_CHECKIN_DISTANCE_TO_HIGHLIGHT=$((1*60*60)) # http dashboard will highlight PLM agent if the last check-in is older then 1h = 60 minutes * 60 seconds
HTML_PLM_CHECKIN_DISTANCE_TO_HIGHLIGHT_COLOR='class="cellSevereEmail"' # cellSevereEmail is defined in ZAPMaaS_htmlFunctions.sh

HTML_PLM_COUNTRY_TO_HIGHLIGHT='NotVenezuela|NotSwitzerland|TypeHerePLMCountryNameToHighlight' # If for any reason you wish to highlight dashboard PLM Agents Status Country, match the Country name here, pipe separated
HTML_PLM_COUNTRY_TO_HIGHLIGHT_COLOR='class="cellAmber"' # cellAmber is defined in ZAPMaaS_htmlFunctions.sh

HTML_TEST_EXECUTION_DISTANCE_TO_HIGHLIGHT=$((4*60*60)) # http portal will highlight test Execution Time if the last test is older then 4h = 60 minutes * 60 seconds
HTML_TEST_EXECUTION_DISTANCE_TO_HIGHLIGHT_COLOR='class="cellAmber"' # cellAmber is defined in ZAPMaaS_htmlFunctions.sh
#
DISTANCE_TEST_EXECUTED_FROM_SITE_TO_IGNORE=$((3*${DAY_IN_SECONDS})) # We will ignore tests not executed within last 3 days (in seconds) as APMaaS stores results for months.
WAIT_ON_ERROR_MAX_NUMBER_OF_CONCURRENT_SESSIONS_EXCEEDED=900 # Wait for this number of seconds when your connection with Dynatrace WebService gets saturated
REFRESH_CONFIG_FILES_OLDER_THEN_DAYS=1 # Files in config directory will be DELETED and refreshed if older then this number of days
DEFAULT_DATE_TIME_FORMAT='+%m/%d/%Y %H:%M:%S' # This is date format returned in your time zone by default
statusDesignator='ACTIVE' # curl will retrieve only ACTIVE tests
### APMaaS_param_local.sh - The End ###