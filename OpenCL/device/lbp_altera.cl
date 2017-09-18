#define SAMPLES 8
    
// sliding window with 8 sample offsets
constant char2   neighborhood[SAMPLES] = 
{
    {-1, -1}, // top left
    { 0, -1}, // top center
    { 1, -1}, // top right

    { 1,  0}, // center right

    { 1,  1}, // bottom right
    { 0,  1}, // bottom center
    {-1,  1}, // bottom left

    {-1,  0}  // center left
};

kernel void lbp(
    global uchar* restrict in,
    global uchar* restrict out,

    const int w, const int h,
    const uchar radius)
{
    int xidx = get_local_id(0) + get_group_id(0) * get_local_size(0);
    int yidx = get_local_id(1) + get_group_id(1) * get_local_size(1);

    // Only continue if a distance 'radius' from the edge
    if( xidx < radius || xidx >= w - radius || yidx < radius || yidx >= h - radius )
        return;   

    const int index = yidx * w + xidx;

    uchar center = in[index];
    uchar result = 0;
    for(int i = 0; i < SAMPLES; i++)
    {
        char2 sample_pos = neighborhood[i] * (char)radius;
        uchar sample = in[index + sample_pos.y * w + sample_pos.x];

        if(sample >= center)
            result |= 1 << i;
    }

    out[index] = result;
}
