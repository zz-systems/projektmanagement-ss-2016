#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "CL/opencl.h"
#include "AOCL_Utils.h"
#include <time.h>
#include <unistd.h>

using namespace aocl_utils;

// OpenCL runtime configuration
cl_platform_id platform = NULL;
unsigned num_devices = 0;
scoped_array<cl_device_id> device; // num_devices elements
cl_context context = NULL;
scoped_array<cl_command_queue> queue; // num_devices elements
cl_program program = NULL;
scoped_array<cl_kernel> kernel; // num_devices elements

scoped_array<cl_mem> input_buf; // num_devices elements
scoped_array<cl_mem> output_buf; // num_devices elements
scoped_array<cl_mem> local_spoints; // num_devices elements

// Problem data.

scoped_array<scoped_aligned_ptr<cl_uchar> > input; // num_devices elements
scoped_array<scoped_aligned_ptr<cl_uchar> > output; // num_devices elements

std::string filename;

scoped_array<uint8_t> input_data;

int32_t width;
int32_t height;
size_t problem_size;

int32_t radius;
int32_t samples;

double system_time;
double kernel_time;

scoped_array<unsigned> n_per_device; // num_devices elements

// Function prototypes
void parse_args(int argc, char** argv);

void load_data();
void store_data();

bool init_opencl();
void init_problem();
void run();
void cleanup();

// Entry point.
int main(int argc, char** argv) {
  parse_args(argc, argv);

  // Initialize OpenCL.
  if(!init_opencl()) {
    return -1;
  }

  load_data();
  // Initialize the problem data.
  // Requires the number of devices to be known.
  init_problem();
  
  // this sleep need to get some time to connect with SignalTap 
  // before runing kernel. 
  printf("Problem inited. Start sleeping...\n");
  
  sleep( 15 );

  printf("End sleeping.\n");

  // Run the kernel.
  run();

  store_data();

  // Free the resources allocated
  cleanup();

  return 0;
}

/////// HELPER FUNCTIONS ///////

// parse cmdline args
// file width height radius samples
void parse_args(int argc, char** argv)
{
    char *end;

    filename        = argv[1];

    width           = strtol(argv[2], &end, 10);
    height          = strtol(argv[3], &end, 10);

    problem_size    = width * height;

    radius          = strtol(argv[4], &end, 10);
    samples         = strtol(argv[5], &end, 10);
}

void load_data()
{
    file_input.resize(problem_size);

    FILE* file = fopen(filename.c_str(), "rb");

    fread(&input_data, sizeof(input_data[0]), input_data.size(), file);

    fclose(file);
}

void store_data()
{
    FILE* file = fopen((filename + ".res").c_str(), "wb");

    fwrite(&system_time, sizeof(system_time), 1, file);
    fwrite(&kernel_time, sizeof(kernel_time), 1, file);

    for(unsigned i = 0; i < num_devices; ++i) {
        fwrite(&output[i], sizeof(cl_uchar), output[i].size(), file)
    }

    fclose(file);
}
// Initializes the OpenCL objects.
bool init_opencl() {
  cl_int status;

  printf("Initializing OpenCL\n");

  if(!setCwdToExeDir()) {
    return false;
  }

  // Get the OpenCL platform.
  platform = findPlatform("Altera");
  if(platform == NULL) {
    printf("ERROR: Unable to find Altera OpenCL platform.\n");
    return false;
  }

  // Query the available OpenCL device.
  device.reset(getDevices(platform, CL_DEVICE_TYPE_ALL, &num_devices));
  printf("Platform: %s\n", getPlatformName(platform).c_str());
  printf("Using %d device(s)\n", num_devices);
  for(unsigned i = 0; i < num_devices; ++i) {
    printf("  %s\n", getDeviceName(device[i]).c_str());
  }

  // Create the context.
  context = clCreateContext(NULL, num_devices, device, NULL, NULL, &status);
  checkError(status, "Failed to create context");

  // Create the program for all device. Use the first device as the
  // representative device (assuming all device are of the same type).
  std::string binary_file = getBoardBinaryFile("lbp_altera", device[0]);
  printf("Using AOCX: %s\n", binary_file.c_str());
  program = createProgramFromBinary(context, binary_file.c_str(), device, num_devices);

  // Build the program that was just created.
  status = clBuildProgram(program, 0, NULL, "", NULL, NULL);
  checkError(status, "Failed to build program");

  // Create per-device objects.
  queue.reset(num_devices);
  kernel.reset(num_devices);
  n_per_device.reset(num_devices);
  input_image_buf.reset(num_devices);
  local_spoints.reset(num_devices);
  output_image_buf.reset(num_devices);

  for(unsigned i = 0; i < num_devices; ++i) {
    // Command queue.
    queue[i] = clCreateCommandQueue(context, device[i], CL_QUEUE_PROFILING_ENABLE, &status);
    checkError(status, "Failed to create command queue");

    // Kernel.
    const char *kernel_name = "vector_add";
    kernel[i] = clCreateKernel(program, kernel_name, &status);
    checkError(status, "Failed to create kernel");

    // Determine the number of elements processed by this device.
    n_per_device[i] = problem_size / num_devices; // number of elements handled by this device

    // Spread out the remainder of the elements over the first
    // N % num_devices.
    if(i < (problem_size % num_devices)) {
      n_per_device[i]++;
    }

    // Input buffers.
    input_buf[i] = clCreateBuffer(context, CL_MEM_READ_ONLY, 
        n_per_device[i] * sizeof(cl_uint), NULL, &status);
    checkError(status, "Failed to create buffer for input");

    // Output buffer.
    output_buf[i] = clCreateBuffer(context, CL_MEM_WRITE_ONLY, 
        n_per_device[i] * sizeof(cl_uint), NULL, &status);
    checkError(status, "Failed to create buffer for output");
  }

  return true;
}

// Initialize the data for the problem. Requires num_devices to be known.
void init_problem() {
  if(num_devices == 0) {
    checkError(-1, "No devices");
  }

  input.reset(num_devices);
  output.reset(num_devices);


  // Generate input vectors A and B and the reference output consisting
  // of a total of N elements.
  // We create separate arrays for each device so that each device has an
  // aligned buffer. 
  for(unsigned i = 0; i < num_devices; ++i) {
    input[i].reset(n_per_device[i]);
    output[i].reset(n_per_device[i]);

    for(unsigned j = 0; j < n_per_device[i]; ++j) {
        size_t offset   = i == 0 
                        ? 0
                        : n_per_device[i - 1];

      input[i][j] = input_data[offset + j];
    }
  }
}

void run() {
  cl_int status;

  const double start_time = getCurrentTimestamp();

  // Launch the problem for each device.
  scoped_array<cl_event> kernel_event(num_devices);
  scoped_array<cl_event> finish_event(num_devices);

  for(unsigned i = 0; i < num_devices; ++i) {

    // Transfer inputs to each device. Each of the host buffers supplied to
    // clEnqueueWriteBuffer here is already aligned to ensure that DMA is used
    // for the host-to-device transfer.
    cl_event write_event;
    status = clEnqueueWriteBuffer(queue[i], input_buf[i], CL_FALSE,
        0, n_per_device[i] * sizeof(cl_uint), input[i], 0, NULL, &write_event);
    checkError(status, "Failed to transfer input");

    // Set kernel arguments.
    unsigned argi = 0;

    // Input
    status = clSetKernelArg(kernel[i], argi++, sizeof(cl_mem), &input_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);

    // Output
    status = clSetKernelArg(kernel[i], argi++, sizeof(cl_mem), &output_buf[i]);
    checkError(status, "Failed to set argument %d", argi - 1);

    // spoints local mem
    status = clSetKernelArg(kernel[i], argi++, sizeof(float) * 2 * samples, NULL);
    checkError(status, "Failed to set argument %d", argi - 1);

    // width
    status = clSetKernelArg(kernel[i], argi++, sizeof(int32_t), &width);
    checkError(status, "Failed to set argument %d", argi - 1);

    // height
    status = clSetKernelArg(kernel[i], argi++, sizeof(int32_t), &height);
    checkError(status, "Failed to set argument %d", argi - 1);

    // radius
    status = clSetKernelArg(kernel[i], argi++, sizeof(int32_t), &radius);
    checkError(status, "Failed to set argument %d", argi - 1);

    // samples
    status = clSetKernelArg(kernel[i], argi++, sizeof(int32_t), &samples);
    checkError(status, "Failed to set argument %d", argi - 1);


    // Enqueue kernel.
    // Use a global work size corresponding to the number of elements to add
    // for this device.
    // 
    // We don't specify a local work size and let the runtime choose
    // (it'll choose to use one work-group with the same size as the global
    // work-size).
    //
    // Events are used to ensure that the kernel is not launched until
    // the writes to the input buffers have completed.
    const size_t global_work_size = n_per_device[i];
    printf("Launching for device %d (%d elements)\n", i, global_work_size);

    status = clEnqueueNDRangeKernel(queue[i], kernel[i], 1, NULL,
        &global_work_size, NULL, 1, &write_event, &kernel_event[i]);
    checkError(status, "Failed to launch kernel");

    // Read the result. This the final operation.
    status = clEnqueueReadBuffer(queue[i], output_buf[i], CL_FALSE,
        0, n_per_device[i] * sizeof(cl_uint), output[i], 1, &kernel_event[i], &finish_event[i]);

    // Release local events.
    clReleaseEvent(write_event);
  }

  // Wait for all devices to finish.
  clWaitForEvents(num_devices, finish_event);

  const double end_time = getCurrentTimestamp();

  kernel_time = 0;
  system_time = (end_time - start_time) * 1e3;

  // Wall-clock time taken.
  printf("\nTime: %0.3f ms\n", system_time);

  // Get kernel times using the OpenCL event profiling API.
  for(unsigned i = 0; i < num_devices; ++i) {
    cl_ulong time_ns = getStartEndTime(kernel_event[i]);
    kernel_time += double(time_ns) * 1e-6;
    printf("Kernel time (device %d): %0.3f ms\n", i, double(time_ns) * 1e-6);
  }

  kernel_time /= num_devices;

  // Release all events.
  for(unsigned i = 0; i < num_devices; ++i) {
    clReleaseEvent(kernel_event[i]);
    clReleaseEvent(finish_event[i]);
  }  
}

// Free the resources allocated during initialization
void cleanup() {
  for(unsigned i = 0; i < num_devices; ++i) {
    if(kernel && kernel[i]) {
      clReleaseKernel(kernel[i]);
    }
    if(queue && queue[i]) {
      clReleaseCommandQueue(queue[i]);
    }
    if(input_buf && input_buf[i]) {
      clReleaseMemObject(input_buf[i]);
    }
    if(output_buf && output_buf[i]) {
      clReleaseMemObject(output_buf[i]);
    }
  }

  if(program) {
    clReleaseProgram(program);
  }
  if(context) {
    clReleaseContext(context);
  }
}