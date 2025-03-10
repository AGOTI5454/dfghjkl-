import moderngl_window as mglw 
import moderngl

class App(mglw.WindowConfig):
    window_size: list = [700, 900]
    resoure_dir: str = 'programs'

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.quad = wglw.geometry.quad_fs()
        self.programs = self.load_program(vertex_shader= 'vertex.glsl', fragment_shader= 'fragment_glal')
        

        self.program['u_resolution'] = self.window_size

    def on_render(self, time, frame_time):
        self.ctx.clear()
        self.quad.render(self.program)

    def on_mouse_position_event(self, x, y, dx, dy):
        self.program["u_mouse"] = (x, y)
        return super().on_mouse_position_event(x, y, dx, dy)
