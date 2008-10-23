
#include <stdexcept>

class FLANNException : public std::runtime_error {
 public:
   FLANNException(const char* message) : std::runtime_error(message) { }
 };



typedef map<const char*,Variant> Params;

