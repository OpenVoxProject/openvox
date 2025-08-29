#include <stdlib.h>

static void explode() __attribute__((constructor));

void explode() {
  exit(42);
}
