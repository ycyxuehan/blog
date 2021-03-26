#include <iostream>
#include <vector>
using namespace std;

vector<vector<int>> randMatrix(int x, int y)
{
    vector<vector<int>> matrix(x);
    for (int i = 0; i < x; i++)
    {
        matrix[i].resize(y);
        for (int j = 0; j < y; j++)
        {
            matrix[i][j] = rand() % 100;
        }
    }
    return matrix;
}

void display(vector<vector<int>> matrix, int x, int y)
{
    for (int i = 0; i < x; i++)
    {
        for (int j = 0; j < y; j++)
        {
            cout << matrix[i][j] << " ";
        }
        cout << endl;
    }
    cout << endl;
}

vector<int> up(vector<vector<int>> matrix, int x, int y)
{
    auto res = vector<int>(3) = {-1, -1, -1};
    if (x == 0)
    {
        return res;
    }
    res[0] = matrix[x - 1][y];
    res[1] = x - 1;
    res[2] = y;
    return res;
}

vector<int> down(vector<vector<int>> matrix, int x, int y)
{
    auto res = vector<int>(3) = {-1, -1, -1};

    auto xlen = matrix.size();
    if (x == xlen - 1)
    {
        return res;
    }
    res[0] = matrix[x + 1][y];
    res[1] = x + 1;
    res[2] = y;
    return res;
}

vector<int> left(vector<vector<int>> matrix, int x, int y)
{
    auto res = vector<int>(3) = {-1, -1, -1};

    if (y == 0)
    {
        return res;
    }
    res[0] = matrix[x][y - 1];
    res[1] = x;
    res[2] = y - 1;
    return res;
}

vector<int> right(vector<vector<int>> matrix, int x, int y)
{
    auto res = vector<int>(3) = {-1, -1, -1};

    auto row = matrix[x];
    auto ylen = row.size();
    if (y == ylen - 1)
    {
        return res;
    }
    res[0] = matrix[x][y + 1];
    res[1] = x;
    res[2] = y + 1;
    return res;
}

vector<vector<vector<int>>> branch(vector<vector<int>> matrix, int x, int y)
{
    auto branch = vector<vector<vector<int>>>(x * y);
    auto index = 0;
    for (int i = 0; i < x; i++)
    {
        for (int j = 0; j < y; j++)
        {
            branch[index].resize(7);
            branch[index][0].resize(1);
            branch[index][0][0] = matrix[i][j];
            branch[index][1].resize(1);

            branch[index][1][0] = i;
            branch[index][2].resize(1);

            branch[index][2][0] = j;

            branch[index][3] = up(matrix, i, j);

            branch[index][4] = down(matrix, i, j);
            branch[index][5] = left(matrix, i, j);
            branch[index][6] = right(matrix, i, j);
            index++;
        }
    }
    return branch;
}

int finditem(vector<vector<vector<int>>> branches, int tx, int ty, int plen = 0)
{
    int ulen, dlen, llen, rlen;
    ulen = dlen = llen = rlen = plen;
    for (auto vi : branches)
    {
        if (vi[1][0] == tx && vi[2][0] == ty)
        { //找到元素
            if (vi[3][0] > vi[0][0])
            { //上
                cout << "up [" << vi[3][0] << "] is great than me [" << vi[0][0] << "]" << endl;
                ulen++;
                ulen = finditem(branches, vi[3][1], vi[3][2], ulen);
            }
            if (vi[4][0] > vi[0][0])
            { //下
                cout << "down [" << vi[4][0] << "] is great than me [" << vi[0][0] << "]" << endl;
                dlen++;
                dlen = finditem(branches, vi[4][1], vi[4][2], dlen);
            }
            if (vi[5][0] > vi[0][0])
            { //左
                cout << "left [" << vi[5][0] << "] is great than me [" << vi[0][0] << "]" << endl;
                llen++;
                llen = finditem(branches, vi[5][1], vi[5][2], llen);
            }
            if (vi[6][0] > vi[0][0])
            { //右
                cout << "right [" << vi[6][0] << "] is great than me [" << vi[0][0] << "]" << endl;
                rlen++;
                rlen = finditem(branches, vi[6][1], vi[6][2], rlen);
            }
        }
    }
    plen = ulen;
    if (plen < dlen)
    {
        plen = dlen;
    }
    if (plen < llen)
    {
        plen = llen;
    }
    if (plen < rlen)
    {
        plen = rlen;
    }
    return plen;
}

int main()
{
    const int x = 4;
    const int y = 4;
    auto matrix = randMatrix(x, y);
    display(matrix, x, y);
    auto branches = branch(matrix, x, y);
    // display(branches, x * y, 7);
    auto plen = finditem(branches, 0, 3);
    cout << matrix[1][2] << "\t" << plen << endl;
    return 0;
}