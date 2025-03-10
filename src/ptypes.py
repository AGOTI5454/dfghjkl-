
type obj = object
type no = None


class Vec3[O]:
    def __init__(self: obj, x: O = 0, y: O = 0, z: O = 0):
        sekf.x = x
        self.y = y
        self.z = z

type Vec2 = Vec3

