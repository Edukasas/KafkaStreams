import datetime
from dateutil.parser import parse as parse_date
import faust
import logging


class ExpediaRecord(faust.Record):
    id: float
    date_time: str
    site_name: int
    posa_container: int
    user_location_country: int
    user_location_region: int
    user_location_city: int
    orig_destination_distance: float
    user_id: int
    is_mobile: int
    is_package: int
    channel: int
    srch_ci: str
    srch_co: str
    srch_adults_cnt: int
    srch_children_cnt: int
    srch_rm_cnt: int
    srch_destination_id: int
    srch_destination_type_id: int
    hotel_id: int


class ExpediaExtRecord(ExpediaRecord):
    stay_category: str


logger = logging.getLogger(__name__)
app = faust.App('kafkastreams', broker='kafka://kafka-0-internal.confluent.svc.cluster.local:9092')
source_topic = app.topic('expedia', value_type=ExpediaRecord)
destination_topic = app.topic('expedia_ext', value_type=ExpediaExtRecord)


@app.agent(source_topic, sink=[destination_topic])
async def handle(messages):
    async for message in messages:
        if message is None:
            logger.info('No messages')
            continue

        #Transform your records here
        try:
            checkin = parse_date(message.srch_ci).date()
            checkout = parse_date(message.srch_co).date()
            num_days = (checkout - checkin).days

            if num_days > 0 and num_days <= 4:
                stay_category = 'Short stay'
            elif num_days > 4 and num_days <= 10:
                stay_category = 'Standard stay'
            elif num_days > 10 and num_days <= 14:
                stay_category = 'Standard extended stay'
            elif num_days > 14:
                stay_category = 'Long stay'
            else:
                stay_category = 'Erroneous data'

            # Convert original message to dict and extend it
            data = message.asdict()

            yield ExpediaExtRecord(**data, stay_category=stay_category)

        except Exception as e:
            logger.error(f"Error processing message {message}: {e}")

if __name__ == '__main__':
    app.main()
