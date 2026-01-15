import base64
import requests
import json
import os

def upload_hash_to_hashtopolis(hashfile, htserver, accesskey, hashisSecret, useBrain, brainFeatures, hashlist_name, hashtype):
    # Set Hashtopolis APIv1 URL.
    ht_api_url = htserver + '/api/user.php'

    # Read every line in the file, and remove any duplicate lines. Then put the lines back into a string variable.
    with open(hashfile, 'r') as file:
        hashlist = file.readlines()
        hash = ''.join(hashlist)
    # Encode the hash variable to base64.
    hash = base64.b64encode(hash.encode()).decode()

    # Create a JSON object with all the required information.
    # Example submit new Hashlist JSON.
    # {
    # "section": "hashlist",
    # "request": "createHashlist",
    # "name": "API Hashlist",
    # "isSalted": false,
    # "isSecret": true,
    # "isHexSalt": false,
    # "separator": ":",
    # "format": 0,
    # "hashtypeId": 22000,
    # "accessGroupId": 1,
    # "data": "$(base64 -w 0 hash.hc22000)",
    # "useBrain": false,
    # "brainFeatures": 0,
    # "accessKey": "mykey"
    # }
    request_json_data = {
    "section": "hashlist",
    "request": "createHashlist",
    "name": "%s" % hashlist_name,
    "isSalted": False,
    "isSecret": hashisSecret,
    "isHexSalt": False,
    "separator": ":",
    "format": 0,
    "hashtypeId": hashtype,
    "accessGroupId": 1,
    "data": "%s" % hash,
    "useBrain": useBrain,
    "brainFeatures":  brainFeatures,
    'accessKey': "%s" % accesskey
    }
    request_json_data = json.dumps(request_json_data)
    # Make a POST web request to Hashtopolis using APIv1 to submit the new hashlist wih 'Content-Type: application/json' header.
    # If the request is successful, then Hashtopolis will return a JSON object with the new hashlist ID.
    # Example: {"section":"hashlist","request":"createHashlist","response":"OK","hashlistId":198}
    # If the request is not successful, then Hashtopolis will return a JSON object with an error message.
    # Example: {"section":"hashlist","request":"createHashlist","response":"ERROR","message":"Invalid hashlist format!"}
    try:
        request = requests.post(ht_api_url, data=request_json_data, headers={'Content-Type': 'application/json'})
    except requests.exceptions.ConnectionError as error_code:
        # If the request fails, send the returned error message to the console.
        print('Failed to connect to the Hashtopolis server. Error: %s' % error_code)
        return
    # Check if the request was successful and the hashlist ID was returned.
    if request.status_code == 200 and 'hashlistId' in request.text:
        # Hashlist upload was successful. Output the sussessful message to the console.
        print('Hashlist upload was successful. Hashlist ID: %s' % json.loads(request.text)['hashlistId'])
        # Rename the file to filename + '.uploaded' to indicate the file has been uploaded to Hashtopolis.
        os.rename(hashfile, hashfile + '.uploaded')
    # If the request fails, send the returned error message to the log.
    if request.status_code != 200 or 'hashlistId' not in request.text:
        #
        print('Hashlist upload failed. Error: %s' % request.text)


# Check the command line arguments.
if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Upload a hashlist to Hashtopolis.')
    # User can define the hashfile argument use a '-f' flag.
    # User can define the htserver argument use a '-s' flag.
    # User can define the accesskey argument use a '-k' flag.
    # User can define the hashisSecret argument use a '-i' flag.
    # User can define the useBrain argument use a '-b' flag.
    # User can define the brainFeatures argument use a '-r' flag.
    # User can define the hashlist_name argument use a '-n' flag.
    # User can define the hashtype argument use a '-t' flag.
    parser.add_argument('-f', '--hashfile', help='The hash file to upload.')
    parser.add_argument('-s', '--htserver', help='The Hashtopolis server URL.')
    parser.add_argument('-k', '--accesskey', help='The access key to use.')
    parser.add_argument('-i', '--hashisSecret', help='Is the hash secret?')
    parser.add_argument('-b', '--useBrain', help='Use brain?')
    parser.add_argument('-r', '--brainFeatures', help='Brain features.')
    parser.add_argument('-n', '--hashlist_name', help='The name of the hashlist.')
    parser.add_argument('-t', '--hashtype', help='The hash type ID.')
    args = parser.parse_args()


    # If the hashisSecret argument not passed, then the default is False.
    if args.hashisSecret is None:
        args.hashisSecret = False

    # If the useBrain argument not passed, then the default is False.
    if args.useBrain is None:
        args.useBrain = False

    # If the brainFeatures argument not passed, then the default is 0.
    if args.brainFeatures is None:
        args.brainFeatures = 0

    upload_hash_to_hashtopolis(args.hashfile, args.htserver, args.accesskey, args.hashisSecret, args.useBrain, args.brainFeatures, args.hashlist_name, args.hashtype)