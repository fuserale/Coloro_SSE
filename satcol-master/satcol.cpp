// satcol.cpp
#include <iostream>
#include <algorithm>
#include <vector>
#include <numeric>
#include <string>
#include <fstream>
#include <sstream>
#include <cassert>

int main(int argc, char* argv[])
{
	if (argc != 3)
	{
		std::cout << "Usage: satcol <k> <file>\n";
		return 0;
	}

	const int k = atoi(argv[1]);
	std::ifstream file(argv[2]);

	if(!file)
	{
		std::cout << "Error: unable to open " << std::string(argv[2]) << ".\n";
		return 0;
	}

	std::string line = "";
	while (std::getline(file, line))
	{
		if (line[0] == 'c')
			continue;

		if (line[0] == 'p')
		{
			std::stringstream ss(line.substr(2));
			std::string token = "";
			ss >> token;
			int n = 0;
			int m = 0;
			ss >> n;
			ss >> m;

			const int num_vars = n * k;
			const int num_clauses = (m * k) + n; 

			std::cout << "p cnf " << num_vars << " " << num_clauses << "\n";

			for (int i = 0; i < (n * k); ++i)
			{
				std::cout << (i + 1) << " ";

				if ((i + 1) % k == 0)
					std::cout << "0\n";
			}
		}

		if (line[0] == 'e')
		{
			std::stringstream ss(line.substr(2));
			int u = -1;
			int v = -1;
			ss >> u;
			ss >> v;

			--u;
			--v;

			assert(u >= 0 && v >= 0);

			std::vector<int> a(k);
			std::iota(a.begin(), a.end(), u * k + 1);

			std::vector<int> b(k);
			std::iota(b.begin(), b.end(), v * k + 1);

			assert(a.size() == b.size() && a.size() == k);

			for (int i = 0; i < k; ++i)
			{
				std::cout << "-" << a[i] << " -" << b[i] << " 0\n";
			}
		}
	}
}
