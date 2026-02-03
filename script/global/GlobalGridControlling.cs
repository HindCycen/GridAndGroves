using Godot;
using System;

public abstract partial class Global {
    public static Vector2 GridLeftUp = new Vector2(2, 4) * PxSize;
    public static Vector2 GridRightDown = new Vector2((float) 7.6, 8) * PxSize;
    public static bool[] UnlockedRows = new bool[5];
    public static bool[] UnlockedCols = new bool[7];
    public static Vector2[,] GridPoints;
    public static GridState[,] GridStates;

    public static bool IsPointInGrid(Vector2 point) {
        return point.X >= GridLeftUp.X && point.X <= GridRightDown.X && point.Y >= GridLeftUp.Y && point.Y <= GridRightDown.Y;
    }

    public static Vector2 FindNearestGridPoint(Vector2 targetPoint) {
        if (GridPoints == null) {
            GD.PrintErr("GridPoints未初始化");
            return new Vector2I(-1, -1);
        }

        Vector2 nearestPoint = new Vector2I(0, 0);
        float minDistanceSquared = GridPoints[0, 0].DistanceSquaredTo(targetPoint);

        for (int col = 0; col < 7; col++) {
            for (int row = 0; row < 5; row++) {
                Vector2 currentPoint = GridPoints[col, row];
                float distanceSquared = currentPoint.DistanceSquaredTo(targetPoint);

                if (distanceSquared < minDistanceSquared) {
                    minDistanceSquared = distanceSquared;
                    nearestPoint = currentPoint;
                }
            }
        }

        return nearestPoint;
    }

    public static void UnlockRow(int row) {
        if (row >= 0 && row < UnlockedRows.Length) {
            UnlockedRows[row] = true;
        }

    }

    public static void UnlockCol(int col) {
        if (col >= 0 && col < UnlockedCols.Length) {
            UnlockedCols[col] = true;
        }
    }

    public static bool IsRowUnlocked(int row) {
        if (row >= 0 && row < UnlockedRows.Length) {
            return UnlockedRows[row];
        }
        return false;
    }

    public static bool IsColUnlocked(int col) {
        if (col >= 0 && col < UnlockedCols.Length) {
            return UnlockedCols[col];
        }
        return false;
    }

    public static void InitUnlockedState() {
        UnlockedRows = [false, true, true, true, false];
        UnlockedCols = [false, true, true, true, true, true, false];
    }

    public static void InitGrids() {
        InitUnlockedState();
        InitOccupyState();
    }

    public static void InitOccupyState() {
        // 初始化二维数组，7列5行
        GridPoints = new Vector2[7, 5];
        GridStates = new GridState[7, 5];

        for (int i = 0; i < 7; i++) {  // 7列
            for (int j = 0; j < 5; j++) {  // 5行
                GridPoints[i, j] = new Vector2(i * GridSize, j * GridSize) +
                    new Vector2(2 * PxSize + HalfGridSize, 4 * PxSize + HalfGridSize);
                GridStates[i, j] = (IsRowUnlocked(j) && IsColUnlocked(i)) ? GridState.Free : GridState.Unable;
            }
        }
    }

    public static Vector2I GetGridCoords(Vector2 point) {
        for (int col = 0; col < 7; col++) {
            for (int row = 0; row < 5; row++) {
                if (GridPoints[col, row].Equals(point)) {
                    return new Vector2I(col, row);  // 返回 (col, row) 坐标
                }
            }
        }
        return new Vector2I(-1, -1);  // 没找到匹配的点
    }

    public static Vector2 GetGridPos(Vector2I coords) {
        if (coords.X >= 0 && coords.X < 7 && coords.Y >= 0 && coords.Y < 5) {
            return GridPoints[coords.X, coords.Y];
        }
        GD.PrintErr("Invalid coordinates");
        return Vector2.Zero;
    }

    public static void SetGridState(int col, int row, GridState state) {
        if (col >= 0 && col < 7 && row >= 0 && row < 5) {  // 检查坐标是否在有效范围内
            GridStates[col, row] = state;
        }
    }

    public static GridState GetGridState(int col, int row) {
        if (col >= 0 && col < 7 && row >= 0 && row < 5) {  // 检查坐标是否在有效范围内
            return GridStates[col, row];
        }
        return GridState.Unable;  // 坐标超出范围时返回默认状态
    }
}