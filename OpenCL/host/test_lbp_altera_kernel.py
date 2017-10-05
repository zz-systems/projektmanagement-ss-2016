#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import absolute_import, print_function

from scipy import ndimage
from PIL import Image
import numpy as np
import pyopencl as cl

import os
os.environ['PYOPENCL_COMPILER_OUTPUT'] = '1'

in_image = Image.open('test.jpg').resize((256, 256), Image.ANTIALIAS).convert('L')
[w, h] = [in_image.size[0], in_image.size[1]]

# add border
# new_size = (in_image.size[0] + 2, in_image.size[1] + 2)
#
# new_im = Image.new("RGB", in_image.size)
#
# new_im.paste(in_image, (round((new_size[0]-in_image.size[0])/2),
#                       round((new_size[1]-in_image.size[1])/2)))
#
# in_image = new_im.convert('L')

in_image_arr = np.array(in_image)
in_image_arr = in_image_arr.ravel()

in_image.show()

print([p.get_devices() for p in cl.get_platforms()])


# CPU OpenCL compilation does not work on osx

#ctx = cl.create_some_context()
platforms = cl.get_platforms()
ctx = cl.Context(
    dev_type=cl.device_type.GPU,
    properties=[(cl.context_properties.PLATFORM, platforms[0])])

queue = cl.CommandQueue(ctx)

mf = cl.mem_flags

in_image_buf = cl.Buffer(ctx, mf.READ_ONLY | mf.COPY_HOST_PTR, hostbuf=in_image_arr)
out_image_buf = cl.Buffer(ctx, mf.WRITE_ONLY, in_image_arr.nbytes)

with open("device/lbp_altera.cl", 'r') as f:
    program_str = f.read()

prg = cl.Program(ctx, program_str).build()



prg.lbp(queue, (w, h), None,
        in_image_buf,
        out_image_buf,
        np.int32(w),
        np.int32(h),
        np.uint8(1)).wait()

result = np.empty_like(in_image_arr)
cl.enqueue_copy(queue, result, out_image_buf)
result = result.reshape([h, w])
out_image = Image.fromarray(result, 'L')
out_image.show()
