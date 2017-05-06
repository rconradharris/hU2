import json
import os

import requests


class BadResponse(Exception):
    pass

class LinkButtonNotPressed(Exception):
    pass


class Bridge(object):
    def __init__(self, ip_address):
        self.ip_address = ip_address

    def request(self, method, url, data):
        full_url = "http://{}{}".format(self.ip_address, url)
        method_func = getattr(requests, method)
        print "{}: {} {}".format(method.upper(), full_url, data)
        if data:
            data = json.dumps(data)
        resp = method_func(full_url, data=data, headers=headers)
        return resp

    def register_app(self, device_type):
        resp = self.request('post', '/api/', {"devicetype": device_type})
        data = resp.json()[0]
        if 'error' in data:
            if data['error']['type'] == 101:
                raise LinkButtonNotPressed
        if 'success' in data:
            username = data['success']['username']
        app = App(self, username)
        app.to_cache()
        return app

    @classmethod
    def discover_nupnp(cls):
        resp = requests.get('https://www.meethue.com/api/nupnp')
        if resp.status_code != 200:
            return None
        data = resp.json()[0]
        return cls(data['internalipaddress'])


class Light(object):
    def __init__(self, app, light_id, name, on, reachable):
        self.app = app
        self.light_id = light_id
        self.name = name
        self.on = on
        self.reachable = reachable

    def request(self, method, url, data):
        return self.app.request(method,
                                '/lights/{}{}'.format(self.light_id, url),
                                data)

    def _turn_on(self, on):
        resp = self.request('put', '/state', {'on': on})
        if resp.status_code != 200:
            raise BadResponse

    def turn_on(self):
        if self.on:
            return
        self._turn_on(True)

    def turn_off(self):
        if not self.on:
            return
        self._turn_on(False)


class App(object):
    def __init__(self, bridge, username):
        self.bridge = bridge
        self.username = username

    def request(self, method, url, data):
        return self.bridge.request(method,
                                   '/api/{}{}'.format(self.username, url),
                                   data)

    def all_on(self):
        for light in lights:
            light.turn_on()

    def all_off(self):
        for light in lights:
            light.turn_off()

    def lights(self):
        resp = self.request('get', '/lights', None)
        if resp.status_code != 200:
            raise BadResponse
        lights = []
        for light_id, ld in resp.json().iteritems():
            state = ld['state']
            light = Light(self, light_id, ld['name'], state['on'],
                          state['reachable'])
            lights.append(light)
        return lights

    def to_cache(self):
        data = json.dumps({"bridge_ip": bridge.ip_address,
                           "username": self.username})
        with open('.app', 'w') as f:
            f.write(data)

    @classmethod
    def from_cache(cls):
        if not os.path.exists('.app'):
            return None
        with open('.app') as f:
            data = json.load(f)
        bridge = Bridge(data['bridge_ip'])
        return cls(bridge, data['username'])




# Start
app = App.from_cache()
if not app:
    # Pair
    bridge = Bridge.discover_nupnp()
    print "ip_address: {}".format(bridge.ip_address)
    app = bridge.register_app('foo')

lights = app.lights()

for light in lights:
    print light.light_id, light.name

#office = light
#office.turn_off()
#app.all_on()
