
kernel void lbp_kernel(
    global uchar* in,
    global uchar* out,
    int2 size, float radius, int samples)
{
    // assume workroup size = image size
    const int2 pos = { get_global_id(0), get_global_id(1) };
    const int index = pos.y * size.x + pos.x;


    float2 spoints[samples];
    float a = 2.0f * M_PI / samples;

    uchar threshold = in[pos.y * size.x + pos.x];
    for(int i = 0; i < samples; i++)
    {
        spoints[i].x = + radius * cos( float( i * a ) );
        spoints[i].y = - radius * sin( float( i * a ) );
    }

    float value;

    for(int i = 0; i < samples; i++)
    {
        float2 fpos = spoints[i];
        int2 ipos = (int2)round(fpos);

        float current_value = in[ipos.y * size.y + ipos.x];

        // Check if interpolation is needed.
		if( (abs_diff( fpos.x, ipos.x ) > 1e-6)
         || (abs_diff( fpos.y, ipos.y ) > 1e-6) )
        {
            int2 ff = pos + (int2)floor(fpos);
            int2 cc = pos + (int2)ceil(fpos);

            int idxV1 = index + size.x * ff.y + ff.x;
			int idxV2 = index + size.x * ff.y + cc.x;
			int idxV3 = index + size.x * cc.y + ff.x;
			int idxV4 = index + size.x * cc.y + cc.x;

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
