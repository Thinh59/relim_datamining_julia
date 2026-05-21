# RELIM — Cài đặt thuật toán Frequent Itemset Mining bằng Julia

Đồ án 2 môn **CSC14004 — Khai thác dữ liệu và ứng dụng**.
Cài đặt thuật toán **RELIM** (*Recursive Elimination*) theo paper gốc của
Borgelt (OSDM 2005).

---

## 1. Yêu cầu hệ thống

- **Julia ≥ 1.9** (ưu tiên 1.10+).
- Hệ điều hành Linux / macOS / Windows.
- Khoảng 200 MB dung lượng cho Julia + các package.

> Project **không phụ thuộc Python**. File `requirements.txt` không cần
> thiết — Julia dùng `Project.toml` (đã có sẵn) để quản lý dependencies.

---

## 2. Cài đặt Julia

### Cách 1 — Cài qua Conda (khuyến nghị nếu bạn đã dùng môi trường Conda)

Phù hợp khi bạn muốn cô lập Julia trong một môi trường Conda riêng (ví dụ
môi trường tên `dm`).

```bash
# Tạo môi trường mới (bỏ qua nếu đã có)
conda create -n dm -y
conda activate dm

# Cài Julia từ kênh conda-forge
conda install -c conda-forge julia -y

# Kiểm tra
julia --version
# -> julia version 1.x.y
```

Mỗi lần làm việc với project, chỉ cần `conda activate dm` rồi chạy `julia`.

### Cách 2 — Cài chính thống bằng `juliaup` (nhanh hơn, không cần Conda)

`juliaup` là trình quản lý phiên bản Julia chính thức.

```bash
# Trên Linux / macOS:
curl -fsSL https://install.julialang.org | sh

# Khởi động lại terminal (hoặc `source ~/.bashrc`)
julia --version
```

Trên Windows, tải installer tại: <https://julialang.org/downloads/>.

---

## 3. Cài dependencies của project

Sau khi đã có `julia` trong PATH, từ thư mục gốc của project chạy **một lần duy nhất**:

```bash
cd relim_datamining_julia
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Lệnh này đọc `Project.toml`, tải về:
- `BenchmarkTools` (đo thời gian L1 vs L3),
- `Random`, `Test` (stdlib, cho unit test).

Lần thứ hai trở đi không cần chạy lại.

---

## 4. Chạy thuật toán (CLI)

### Cú pháp

```bash
julia --project=. src/main.jl --input <FILE> --minsup <VAL> \
                              [--output <FILE>] [--absolute]
```

| Tham số | Bắt buộc | Ý nghĩa |
|---------|----------|---------|
| `--input PATH` | có | File giao dịch định dạng SPMF (mỗi dòng = 1 transaction, item cách nhau bởi khoảng trắng). |
| `--minsup VAL` | có | Ngưỡng minsup. Mặc định hiểu là **tỉ lệ** thuộc `[0, 1]`. |
| `--output PATH` | không | File kết quả. Mặc định: `frequent_itemsets.txt`. |
| `--absolute` | không | Cờ. Nếu có, `minsup` được hiểu là **số tuyệt đối** (số giao dịch). |
| `--help` / `-h` | không | In hướng dẫn rồi thoát. |

### Ví dụ

**Chạy với minsup tương đối (50%):**

```bash
julia --project=. src/main.jl \
    --input data/toy/example_basic.txt \
    --minsup 0.5 \
    --output result.txt
```

**Chạy với minsup tuyệt đối (≥ 1000 giao dịch):**

```bash
julia --project=. src/main.jl \
    --input data/benchmark/chess.txt \
    --minsup 1000 --absolute \
    --output chess_out.txt
```

### Định dạng output

Mỗi dòng có dạng:

```
i1 i2 ... ik #SUP: count
```

Ví dụ: `2 3 5 #SUP: 2` nghĩa là itemset `{2, 3, 5}` xuất hiện trong 2 giao dịch.
Đây là định dạng chuẩn của thư viện SPMF, dễ so sánh / diff trực tiếp.

---

## 5. Chạy bộ test

```bash
julia --project=. tests/test_correctness.jl
```

Kết quả mong đợi:

```
Test Summary:     | Pass  Total  Time
RELIM correctness |   18     18  ~1.5s
```

Bộ test bao gồm:
- Toy database từ paper,
- Các trường hợp biên (DB rỗng, không item phổ biến, tất cả item phổ biến),
- So sánh phiên bản có / không bật `counter_only`,
- 10 trial ngẫu nhiên đối chứng với brute-force.

---

## 6. Cấu trúc thư mục

```
relim_datamining_julia/
├── Project.toml              # Đặc tả dependencies (Julia)
├── README.md                 # File này
├── src/
│   ├── main.jl               # CLI entry point
│   ├── structures.jl         # Cấu trúc dữ liệu: mảng A + linked list
│   ├── utils.jl              # I/O định dạng SPMF + parse CLI
│   └── algorithm/
│       ├── relim.jl          # Thuật toán RELIM
│       └── visualize.jl      # Visualize từng bước
├── tests/
│   ├── test_correctness.jl   # Unit test (so brute-force)
│   └── test_benchmark.jl     # Benchmark + so với SPMF
├── data/
│   ├── toy/                  # CSDL nhỏ cho ví dụ tay
│   ├── benchmark/            # CSDL benchmark (chess, mushroom, retail, ...)
│   └── real_world/           # CSDL thực tế (Market Basket)
├── notebooks/
│   └── demo.ipynb            # Demo phần ứng dụng
└── docs/
    ├── relim.pdf             # Paper gốc Borgelt 2005
    └── Report.pdf            # Báo cáo chính (compile từ Report/main.tex)
```

---

## 7. Khắc phục sự cố thường gặp

### `julia: command not found`

-> Chưa cài Julia, hoặc chưa kích hoạt môi trường Conda. Quay lại **Mục 2**.

### `LoadError: ArgumentError: Package ... not found in current path`

-> Chưa cài dependencies. Chạy lại lệnh ở **Mục 3**:
```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

### Test chạy chậm hoặc treo

-> Lần đầu chạy Julia phải biên dịch JIT, mất thêm vài giây.
Lần thứ hai sẽ nhanh hơn nhiều nhờ cache.

### Kết quả khác SPMF

-> Kiểm tra: (i) định dạng input đúng SPMF chưa, (ii) cách hiểu `minsup` (tỉ lệ
hay tuyệt đối) có đồng nhất với SPMF không. Mặc định project hiểu là **tỉ lệ**;
SPMF GUI cũng nhận tỉ lệ.

---

## 8. Tài liệu tham khảo

- Borgelt, C. (2005). *Keeping Things Simple: Finding Frequent Item Sets by
  Recursive Elimination*. OSDM '05. — Paper gốc, xem `docs/relim.pdf`.
- SPMF Library: <https://www.philippe-fournier-viger.com/spmf/Relim.php>
- Borgelt RELIM reference: <https://borgelt.net/relim.html>
