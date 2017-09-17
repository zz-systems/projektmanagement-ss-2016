#pragma OPENCL EXTENSION cl_amd_printf : enable
#pragma OPENCL EXTENSION cl_intel_printf : enable
#define __ROUNDING_MODE__ rte

// round @GTX1080 TI yields TOTALLY wrong results.
// Own implementation.
inline int my_round (float x) {
   return (int)((x >= 0.0f) ? floor(x + 0.5f) : ceil(x - 0.5f));
}

kernel void lbp(
    global uchar* in,
    global uchar* out,
    local float2* spoints,

    const int w, const int h,
    const float radius,
    const int samples)
{
    int xidx = get_local_id(0) + get_group_id(0) * get_local_size(0);
    int yidx = get_local_id(1) + get_group_id(1) * get_local_size(1);

    const int index = yidx * w + xidx;
    const int2 pos = { index / w, index % w };

    // Only continue if a distance 'radius' from the edge
    if( pos.x < radius || pos.x >= w - radius || pos.y < radius || pos.y >= h - radius )
        return;

    float a = 2.0f * M_PI / samples;
    for(int i = 0; i < samples; i++)
    {
        spoints[i].x = + radius * cos( float( i * a ) );
        spoints[i].y = - radius * sin( float( i * a ) );
    }

    float value = 0;
    uchar threshold = in[index];


    for(int i = 0; i < samples; i++)
    {
        float2 fpos = spoints[i];
        int2 ipos = {my_round(fpos.x), my_round(fpos.y)};//(int2)round(fpos);

        // memory access violations occured with native round.
        /*if(index + ipos.y * w + ipos.x > w * h)
            printf("dim: %i, iposx: %i, iposy: %i, fposx: %f, fposy: %f, offset: %i, index: %i\n",
            w * h,
            ipos.x, ipos.y,
            fpos.x, fpos.y,
            index,  index + ipos.y * w + ipos.x);
        */
        float current_value = in[index + ipos.y * w + ipos.x];

        // Check if interpolation is needed.
        if( (abs_diff( fpos.x, ipos.x ) > 1e-6)
         || (abs_diff( fpos.y, ipos.y ) > 1e-6) )
        {
            int2 ff = (int2)floor(fpos);
            int2 cc = (int2)ceil(fpos);

            int idxV1 = index + w * ff.y + ff.x;
            int idxV2 = index + w * ff.y + cc.x;
            int idxV3 = index + w * cc.y + ff.x;
            int idxV4 = index + w * cc.y + cc.x;

            // Calculate the interpolation weights.
            float2 tt = fpos - ff;

            float w1 = (1 - tt.x) * (1 - tt.y);
            float w2 = tt.x * (1 - tt.y);
            float w3 = (1 - tt.x) * tt.y;
            float w4 = tt.x * tt.y;

            current_value   = in[idxV1] * w1
                            + in[idxV2] * w2
                            + in[idxV3] * w3
                            + in[idxV4] * w4;
        }

        value += current_value - threshold >= 0 ? pow(2.0f, i) : 0;
    }

    out[index] = (uchar)value;
}
