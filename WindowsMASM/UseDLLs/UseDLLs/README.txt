THIS PROGRAM USES THE DLL_Skeleton.dll and the DynamicLinkLibrary.lib files that
were obtain by running the previous program DynamicLinkLibrary.
In order for this program to access the processes that are located within the library
we must have both these files in the current directory were this program lives in !

In this implementation we are going to be using the Windows loader via the
includelib directive and type in the name of our .lib file which in this case is
DynamicLinkLibrary.lib