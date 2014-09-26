/*
 * If you want to get coverage information on a file when you run a
 * particular test, you have to #include it (generally this means including
 * .c files).  Conversely if you don't want to get coverage information on
 * a file with a particular test, you can link against.
 *
 * Often one uses the preprocessor to redirect access to functions in order
 * to override their behavior for testing.  Below is an example of redirecting
 * the main function.
 */

#define main my_main
#include "../src/myprog.c"
#undef main

#include <assert.h>

int main (void) 
  {
    int rv;
    
    rv = my_main ();
    assert (! rv);

    return 0;
  }
