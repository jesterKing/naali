import math
import random
import json
import socket #just for exception handling for restarts here

import circuits
import eventlet
from eventlet import websocket
from PythonQt.QtGui import QVector3D as Vec3
from PythonQt.QtGui import QQuaternion as Quat

import naali
import rexviewer as r
import mathutils

import async_eventlet_wsgiserver

SPAWNPOS = 131.806, 48.9571, 28.7691 #at the end of pier in w.r.o:9000

class NaaliWebsocketServer(circuits.BaseComponent):
    instance = None

    def __init__(self):
        circuits.BaseComponent.__init__(self)
        print "websocket listen.."
        self.sock = eventlet.listen(('0.0.0.0', 9999))
        print "..done"
        self.server = async_eventlet_wsgiserver.server(self.sock, handle_clients)
        print "websocket server started."

        NaaliWebsocketServer.instance = self
        self.previd = 500000
        self.clientavs = {}

    def newclient(self, clientid, position, orientation):
        #self.clients.add()
        ent = r.createEntity("Jack.mesh", self.previd)
        self.previd += 1

        ent.placeable.Position = Vec3(position[0], position[1], position[2])
        print Quat(mathutils.euler_to_quat(orientation))
        ent.placeable.Orientation = Quat(mathutils.euler_to_quat(orientation))

        print "New entity for web socket presence at", ent.placeable.Position

        self.clientavs[clientid] = ent

    def updateclient(self, clientid, position, orientation):
        ent = self.clientavs[clientid]
        ent.placeable.Position = Vec3(position[0], position[1], position[2])
        ent.placeable.Orientation = Quat(mathutils.euler_to_quat(orientation))

    @circuits.handler("update")
    def update(self, t):
        if self.server is not None:
            self.server.next()

    @circuits.handler("on_exit")
    def on_exit(self):
        # Need to figure something out what to do and how
        pass

clients = set()
       
def sendAll(data):
    for client in clients:
        client.send(json.dumps(data))        

@websocket.WebSocketWSGI
def handle_clients(ws):
    print 'START', ws
    myid = random.randrange(1,10000)
    clients.add(ws)
    
    while True:
            
        try:
            msg = ws.wait()
        except socket.error:
            #if there is an error we simply quit by exiting the
            #handler. Eventlet should close the socket etc.
            return

        print msg

        if msg is None:
            # if there is no message the client has quit. 
            return

        try:
            function, params = json.loads(msg)
        except ValueError, error:
            print error

        if function == 'CONNECTED':
            ws.send(json.dumps(['initGraffa', {}]))

            x, y, z = SPAWNPOS[0], SPAWNPOS[1], SPAWNPOS[2]
            position = (x, y, z)
            orientation = (1.57, 0, 0)
            NaaliWebsocketServer.instance.newclient(myid, position, orientation)

            ws.send(json.dumps(['setId', {'id': myid}]))
            sendAll(['newAvatar', {'id': myid, 'position': position, 'orientation': orientation}])

        elif function == 'Naps':
            ws.send(json.dumps(['logMessage', {'message': 'Naps itelles!'}]))
            
        elif function == 'giev update':
            print params
            id = params.get('id')
            position = params.get('position')
            orientation = params.get('orientation')
            print 'orioriori', orientation
            NaaliWebsocketServer.instance.updateclient(myid, position, orientation)
            
            scene = naali.getScene("World")
            ents = scene.GetEntitiesWithComponentRaw("EC_OpenSimPresence")

            for ent in ents:

                x = ent.placeable.Position.x()
                y = ent.placeable.Position.y()
                z = ent.placeable.Position.z()

                orientation = mathutils.quat_to_euler(ent.placeable.Orientation)

                id = ent.Id

                sendAll(['updateAvatar',
                         {'id': id,
                          'position': (x, y, z),
                          'orientation': orientation,
                          }])

                
        elif function == 'setSize':
            y_max = params['height']
            x_max = params['width']

        elif function == 'reboot':
            break
    clients.remove(ws)
    print 'END', ws

def handle_move():
    pass

if __name__ == '__main__':
    sock = eventlet.listen(('0.0.0.0', 9999))
    server = async_eventlet_wsgiserver.server(sock, hello_world)
    
    while True:
        server.next()
        print 'TICK'
     