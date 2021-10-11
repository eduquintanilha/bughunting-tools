#!/bin/bash

if [ "$1" = "" ]
then
    printf "\n# Usage: $0 <GOOGLE_MAPS_API_KEY>"
    exit
fi

API_KEY=$1

declare -a URLS=("https://maps.googleapis.com/maps/api/staticmap?center=45,10&zoom=7&size=400x400&key="
"https://maps.googleapis.com/maps/api/streetview?size=400x400&location=40.720032,-73.988354&fov=90&heading=235&pitch=10&key="
"https://www.google.com/maps/embed/v1/place?q=place_id:ChIJyX7muQw8tokR2Vf5WBBk1iQ&key="
"https://maps.googleapis.com/maps/api/directions/json?origin=Disneyland&destination=Universal+Studios+Hollywood4&key="
"https://maps.googleapis.com/maps/api/geocode/json?latlng=40,30&key="
"https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=40.6655101,-73.89188969999998&destinations=40.6905615,-73.9976592|40.6905615,-73.9976592|40.6905615,-73.9976592|40.6905615,-73.9976592|40.6905615,-73.9976592|40.6905615,-73.9976592|40.659569,-73.933783|40.729029,-73.851524|40.6860072,-73.6334271|40.598566,-73.7527626|40.659569,-73.933783|40.729029,-73.851524|40.6860072,-73.6334271|40.598566,-73.7527626&key="
"https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=Museum of Contemporary Art Australia&inputtype=textquery&fields=photos,formatted_address,name,rating,opening_hours,geometry&key="
"https://maps.googleapis.com/maps/api/place/autocomplete/json?input=Bingh&types=(cities)&key="
"https://maps.googleapis.com/maps/api/elevation/json?locations=39.7391536,-104.9847034&key="
"https://maps.googleapis.com/maps/api/timezone/json?location=39.6034810,-119.6822510&timestamp=1331161200&key="
"https://roads.googleapis.com/v1/nearestRoads?points=60.170880,24.942795|60.170879,24.942796|60.170877,24.942796&key="
"https://www.googleapis.com/geolocation/v1/geolocate?key=")

printf "\n\n# API_KEY => $API_KEY \n\n"
for url in ${URLS[*]}
    do
        printf "# Testing => $url$API_KEY \n\n"
        curl --insecure -k $url$API_KEY
        printf "\n\n##########################################\n\n"
    done
