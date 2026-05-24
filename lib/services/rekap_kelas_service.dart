import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RekapKelasService {
  Future<String?> downloadRekapKelas({
    required String namaGuru,
    required String nip,
    required String namaKelas,
    required String namaMapel,
    required String semester,
    required String tahunAjaran,
    required List<Map<String, dynamic>> rekapList,
  }) async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) return null;
      }

      final excel = Excel.createExcel();
      final sheet = excel['Rekap Nilai'];
      excel.delete('Sheet1');

      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#0F2D5C'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final labelStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString('#0F2D5C'),
      );

      // ── Judul ────────────────────────────────────────────────────
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('E1'));
      final judulCell = sheet.cell(CellIndex.indexByString('A1'));
      judulCell.value = TextCellValue('REKAP NILAI TUGAS HARIAN');
      judulCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#0F2D5C'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

      // ── Info Guru & Kelas ─────────────────────────────────────────
      final infoData = [
        ['Nama Guru', namaGuru],
        ['NIP', nip.isEmpty ? '-' : nip],
        ['Kelas', namaKelas],
        ['Mata Pelajaran', namaMapel],
        ['Semester', 'Semester $semester - $tahunAjaran'],
      ];

      for (int i = 0; i < infoData.length; i++) {
        final row = i + 2;
        final cellLabel = sheet.cell(CellIndex.indexByString('A$row'));
        cellLabel.value = TextCellValue(infoData[i][0]);
        cellLabel.cellStyle = labelStyle;

        final cellColon = sheet.cell(CellIndex.indexByString('B$row'));
        cellColon.value = TextCellValue(':');

        sheet.merge(
          CellIndex.indexByString('C$row'),
          CellIndex.indexByString('E$row'),
        );
        final cellValue = sheet.cell(CellIndex.indexByString('C$row'));
        cellValue.value = TextCellValue(infoData[i][1]);
      }

      // ── Header Tabel ──────────────────────────────────────────────
      const headerRow = 8;
      final headers = [
        'No',
        'Nama Siswa',
        'Rata-rata Teori',
        'Rata-rata Praktikum',
        'Nilai Akhir Tugas',
      ];

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: headerRow - 1),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // ── Data Siswa ────────────────────────────────────────────────
      for (int i = 0; i < rekapList.length; i++) {
        final r = rekapList[i];
        final siswa = r['siswa'];
        final rowIndex = headerRow + i;
        final nilaiAkhir = (r['nilai_akhir'] as num).toDouble();

        final rowBg = i % 2 == 0
            ? ExcelColor.fromHexString('#FFFFFF')
            : ExcelColor.fromHexString('#F8FAFC');

        String nilaiColorHex;
        if (nilaiAkhir >= 80) {
          nilaiColorHex = '#059669';
        } else if (nilaiAkhir >= 60) {
          nilaiColorHex = '#D97706';
        } else {
          nilaiColorHex = '#DC2626';
        }

        // No
        final cellNo = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        );
        cellNo.value = IntCellValue(i + 1);
        cellNo.cellStyle = CellStyle(
          backgroundColorHex: rowBg,
          horizontalAlign: HorizontalAlign.Center,
        );

        // Nama Siswa
        final cellNama = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
        );
        cellNama.value = TextCellValue(siswa['nama_siswa'] ?? '-');
        cellNama.cellStyle = CellStyle(backgroundColorHex: rowBg);

        // Rata-rata Teori
        final cellTeori = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
        );
        cellTeori.value = DoubleCellValue((r['rata_materi'] as num).toDouble());
        cellTeori.cellStyle = CellStyle(
          backgroundColorHex: rowBg,
          horizontalAlign: HorizontalAlign.Center,
        );

        // Rata-rata Praktikum
        final cellPraktikum = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
        );
        cellPraktikum.value = DoubleCellValue(
          (r['rata_praktikum'] as num).toDouble(),
        );
        cellPraktikum.cellStyle = CellStyle(
          backgroundColorHex: rowBg,
          horizontalAlign: HorizontalAlign.Center,
        );

        // Nilai Akhir
        final cellAkhir = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
        );
        cellAkhir.value = DoubleCellValue(nilaiAkhir);
        cellAkhir.cellStyle = CellStyle(
          backgroundColorHex: rowBg,
          fontColorHex: ExcelColor.fromHexString(nilaiColorHex),
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // ── Lebar Kolom ───────────────────────────────────────────────
      sheet.setColumnWidth(0, 6);
      sheet.setColumnWidth(1, 32);
      sheet.setColumnWidth(2, 20);
      sheet.setColumnWidth(3, 22);
      sheet.setColumnWidth(4, 20);

      // ── Simpan File ───────────────────────────────────────────────
      final bytes = excel.encode();
      if (bytes == null) return null;

      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final fileName =
          'Rekap_${namaKelas}_${namaMapel}_Sem${semester}_${tahunAjaran.replaceAll('/', '-')}.xlsx'
              .replaceAll(' ', '_');

      final file = File('${dir!.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      return null;
    }
  }
}
