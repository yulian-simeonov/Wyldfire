# Wyldfire app

## Development Mode

To work with the development server dev.wyldfireapp.com, go to Global Setting on the phone or Simulator, 
scroll down to the apps settings, enter to Wyldfire app settings and toggle Development Mode. 
It works immediately, in dev mode it sends all requests to dev server, otherwise to api server.

## Invite System Overview

We want the user onboarding process to be as simple as possible, while still meeting our goals and processes
for a female invite-driven system.  Additionally, we want to focus on certain markets and control growth
to a certain extent, to ensure that we don't blow up overnight and have scalability issues.

Here are the basic steps.  See "API Commands" section below for more details on each API call.

  1.  A user connects with Facebook

  2.  Check to see if they already have an account

      a.  If they don't have an account, continue to the next step

      b.  If they have an account, let them use the actual app

  3.  API call to check if they are inside a supported geofence with an available spot:
      `/wf/geofence?latitude=34.0359784&longitude=-118.4570998`

      a.  If they are in a supported area with an available spot, the response will be "200/OK".
          In this case, continue to the next step.

      b.  If they are not in a supported area, the response will be "404/unsupported area".
          In this case, send them to "area.wyldfireapp.com" in a webview within the app.

      c.  If they are in a supported area, but there isn't an available spot, the response will be "400/no spots".
          In this case, send them to "spots.wyldfireapp.com" in a webview within the app.

  4.  _Males Only:_ If they are male, they will be told they can either request an invite if they haven't already received one (see Step 7)
      or enter their invite code.  This is checked with the API call: `/invitation/redeem?code=XXXXX`.
      (Make sure to store this phone number for use in Step 9.)

      a.  If it is a valid code with an invite in our system, response will be "200/OK", and they can
          continue setup as normal

      b.  If the entered code is not in our system, response will be "404/no invite".
          If the code has already been redeemed, response will be "410/already redeemed".
          In either case, the male user should be shown the reasoning for a rejected code, and then be
          prompted to ask a female friend for an invitation.
          See Step 7

  5.  Create an account: `/wf/add?...`, making sure to include the required parameters:

      - access_token
      - latitude
      - longitude

      (Obviously for males, this is completed only if they passed the invite stage in the previous step.)

      On return login and secret are provided to be used by the app for subsequent API calls.

  6.  Setup account (photos, etc.)

  7.  Invite male friends/request an invitation

      a.  Ask the user to access their phone contacts; we need this info in order to send a text message invitation.

      b.  Present the user with their contacts and have them choose whom to invite/request an invitation

      c.  When the user selects the contact, open up a new text (within the app) to that person with prepopulated copy:
          "I think you would make Wyldfire's network great. Enter the code: XXX. Download the app here: [link to the app in the App Store]"

      d.  Repeat substeps 6b. - 6d. if the user wishes

  8.  At this point, the user may now use the app as normal if:

      a.  They are female and have sent at least one invitation

      b.  They are male and entered a correct invite code (see Step 5)

      If this is the case, put their location so others can see them in Browse: `/location/put...`

      If, on the other hand, they are a male user still waiting on an invitation, they are limited to viewing Trending only.
      They may also request further invitations (no limit on how many female friends they can ask).


## Client app operations flow

  1. Login into the app: `/wf/login?access_token=XXX`

     Returns information about current account or other accounts, all account columns are returned for the current account
     and only public columns returned for other accounts. This ensures that no private fields are ever exposed to other API clients.
     This call can also be used to login into the service or verify if the given login and secret are valid.

     After the first login, subsequent account calls to be executed with `/account/get` until receive 412 error code, this means the access
     token from FB must be sent again.

    *NOTE: This call DOES NOT require secure signature but MUST be over SSL*

     Parameters:

     - If no id is given, returns only one current account record as JSON
     - `id=id,id,...` - return information about given account(s),
       the id parameter can be a single account id or list of ids separated by comma, return list of account records as JSON
     - `_session` - after successful login setup a session with cookies so the Web app can perform requests without signing

       a. If no login, status=404, then register: `/wf/add`
       b. if status=412, this means the secret expired, login with FB access token, `/wf/login?access_token=XXXX`
       c. If status 401 this is from Facebook regarding wrong access_token, re-login with Facebook and try again
       d. Pull all icons from the account object: icon0 .. icon9
       e. Upload profile icons: `/account/put/icon?type=0-9&icon=BASE64-encoded-icon`
          POST or JSON post can be used instead of GET
          - specify `_width` and `_height` with maximum image size on the phone, no need to download extra data and downscale it all the time


  2. Start events watcher:
      1. Issue `/account/subscribe` call, this is a Long Poll, it will wait indefinitely for events
      2. Read all pending messages `/message/get/new?_archive=1`
          - pull the list, store in local storage, notify main UI thread, sort by mtime
      3. Read all pending matches `/connection/get?mtime=last-mtime`
          - pull the list, store in local storage, notify main UI thread
      4. If needed, read current stats on the account `/wf/stats`, this will return all counters and weekly views/likes
      5. Wait for events, once get notification, restart the watcher process again with all the actions 1-3

  3. Connection operations:
      - To mark profile as viewed (in profile view screen only): `/wf/view?id=profile_id`
      - To add connection 'hint': `/connection/add?id=profile_id&type=hint`
      - List all hints sent in the last 24 hours: mtime=Date.now()-86400000: `/connection/get?type=hint&mtime=1398807569354&_ops=mtime,ge`
      - List all hints for a user: `/connection/get?type=hint&id=profile_id`

  4. Messages/chats:
      - To read all new messages for me: `/message/get`
      - To read all new messages for me and mark them as archived: `/message/get?_archive=1`
      - To mark a message as archived/read: `/message/archive?mtime=mtime&sender=sender`, use values for mtime/sender from each message
      - To read icon in the message: `/message/image?mtime=mtime&sender=sender`
      - To send a message: `/message/add?id=id&msg=TEXT`
      - To get all messages from the sender 12345: `/message/get/archive?sender=12345`, optional mtime make it return messages only after specified time in ms
      - To get all messages I have sent to the user 12345: `/message/get/sent?recipient=12345`, optional mtime make it return messages only after specified time in ms

  5. To pull trending list: `/wf/top?gender=f&age=20,30&latitude=lt&longitude=ln`
     returns list of accounts around the current area, distance can be used to limit the area,
     gender can be "f", "m" or "f,m". Age must be 2 numbers.

  6. To get the list for browsing:
      - first call: `/wf/browse?gender=f,m&age=20,50&distance=100&latitude=lt&longitude=ln`
        It returns data.next_token if there are more results within the distance
      - gender can be "f", or "m", or "f,m"
      - distance is in km, default is 5km
      - age must be 2 numbers if need to restrict by age
      - continue browsing passing next_token from the previous result, just append to previous query: `&_token=data.next_token`
      - each record in the result will contain: account id, distance

## API Calls (Wyldfire Specific)

### Call: `/invitation/new`

#### Purpose

For females to generate new invite code

NOTE: The bk_counter table now has two properties: maxinvites and sentinvites, /wf/stats call 
returns them as well as /counter/get

  - maxinvites - how many invites are available at the moment
  - sentinvites - how many invites have been already sent


#### Returns

  - 200 / { code: "XXX", maxinvites: N, sentinvites: N }
  - 403 / "Not allowed to invite" if not a female account

#### Example

  `/invitation/new`

---

### Call: `/invitation/get`

#### Purpose

See who I've invited, and therefore also how many people I've invited

#### Returns

List of phone numbers the current account has invited

---

### Call: `/invitation/redeem`

#### Purpose

For redeeming a code

#### Parameters

  - code (Entered code)

#### Returns

  - 200 / "OK" if it's a valid, unredeemed code
  - 400 / "number required" if no phone number was sent
  - 404 / "no invite" if the phone number isn't in our system
  - 410 / "already redeemed" if it's already been used

#### Example

  `/invitation/redeem?code=ABC`

---

### Call: `/wf/add`

#### Purpose

Replaces /account/add, decrements available spots in the area

*NOTE: This call DOES NOT require secure signature but MUST be over SSL*

#### Parameters

Parameter          | Type
-------------------|--------
access_token       | text (required)
latitude           | (required)
longitude          | (required)
name               | text
secret             | text
login              | text
status             | text ("ok", "reported", "disabled", etc.)
geohash            | text
gender             | text: "m" or "f"
birthday           | text
phone              | text
ishinted           | integer
facebook_id        | integer
facebook_username  | text
facebook_email     | text
facebook_friends   | text
instagram_id       | text
instagram_username | text
device_id          | text
register0          | text
matchable0         | integer
notifications0     | integer
vibrations0        | integer
distance0          | integer
trending_distance0 | integer
age0               | integer
age1               | integer
men0               | integer
women0             | integer

#### Returns

  - JSON of the added account if successful with login and secret to be saved by the app and used in subsequent API calls
  - 400 / "Facebook credentials are required" if you forgot to include the access_token
  - 400 / "latitude/longitude are required" if you forgot to include the coordinates
  - 400 / "Facebook account must have email" if the Facebook profile fields doesn't match the token
  - 400 / "Facebook account must have gender" if the Facebook profile field doesn't match the token
  - 401 / problem with Facebook access token, need to get valid token form FB adn retry

#### Example

  `/wf/add?latitude=34.0359784&longitude=-118.4570998&access_token=CAACEdEose0...ZAwZD`

---

### Call: `/wf/browse`

#### Purpose

Get a list of IDs to browse that meet certain criteria

#### Parameters

  - `age`: must be 2 numbers separated by a comma to indicate range
  - `distance`: in km, default is 5km
  - `gender`: can be "f", or "m", or "f,m"
  - `latitude`
  - `longitude`
  - `_token`: to continue browsing by passing next_token from previous result,
    just append `data.next_token` to previous query

#### Returns

  - List of records, each of which will contain account id and distance
  - data.next_token if there are more results within the distance

#### Example

  `/wf/browse?gender=f,m&age=20,50&latitude=34.0359784&longitude=-118.4570998&distance=100`

---

### Call: `/wf/complaint`

#### Purpose

Reports another user for bad behavior

#### Parameters

  - id (User ID of the user being reported, not the current account ID)
  - descr (Reason for the complaint)

#### Returns

  - 200 / "ok" if successful
  - 400 / "id and descr are required" if the required parameters weren't sent
  - 404 / "no account" if the account being complained about doesn't exist

#### Example

  `/wf/complaint?id=1239874560&descr=inappropriate-message`

---

### Call: `/wf/contact`

#### Purpose

Return info about contacts from the Notebook

#### Parameters

  - id: optional; if specified, returns info about that one particular contact.
    If not specified, returns info about all contacts from Notebook

#### Examples

  `/wf/contact`

  `/wf/contact?id=1239874560`

---

### Call: `/wf/geofence`

#### Purpose

Check current location to see if it is supported by the service and if there is an available spot

#### Parameters

  - latitude
  - longitude

#### Returns

  - 200 / "OK" if they area within a supported area and there is an available spot
  - 404 / "unsupported area" if they are not in a supported area
  - 400 / "no spots" if they are in a supported area, but there isn't an available spot

#### Example

  `/wf/geofence?latitude=34.0359784&longitude=-118.4570998`

---

### Call: `/wf/login`

#### Purpose

For cases when simple `/account/get` returns 412 which means we need a new secret.
It returns the new secret that the app needs to save and use from now on.

NOTE: This is not a substitute for `/account/get`, it connects to Facebook to
verify the access_token which means it is slower.

*NOTE: This call DOES NOT require secure signature but MUST be over SSL*

#### Parameters

  - access_token: Facebook access token

#### Returns

  - JSON with the new secret that the app needs to save and use from now on
  - 404 / "not found" if the login doesn't exist
  - 401 - Facebook access_token is invalid

#### Example

  `/wf/login?access_token=CAACEdEose0...ZAwZD`

---

### Call: `/wf/stats`

#### Purpose

Read current stats on the account

NOTE: This is a heavy call, dont use it very frequently

#### Returns

All counters and weekly views/likes

---

### Call: `/wf/top`

#### Purpose

Pulls the Trending list

NOTE: The list does not change often, do nto call very often

#### Parameters

  - `age`: must be 2 numbers separated by a comma to indicate range
  - `distance`: in km, default is 5km
  - `gender`: can be "f", or "m", or "f,m"
  - `latitude`
  - `longitude`

#### Returns

List of account IDs that meet the specified criteria

#### Example

  `/wf/top?gender=f,m&age=20,50&latitude=34.0359784&longitude=-118.4570998&distance=100`

---

### Call: `/wf/view`

#### Purpose

To mark profile as viewed (in profile view screen only)

#### Parameters

  - id: ID of the account that has been viewed

#### Example

  `/wf/view?id=1239874560`

---
