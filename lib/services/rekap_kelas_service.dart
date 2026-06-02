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

      // ── Style ────────────────────────────────────────────────────
      final navyBg = ExcelColor.fromHexString('#0F2D5C');
      final whiteFg = ExcelColor.fromHexString('#FFFFFF');
      final softBg = ExcelColor.fromHexString('#F8FAFC');
      final mutedFg = ExcelColor.fromHexString('#6B7280');
      final darkFg = ExcelColor.fromHexString('#1A1F36');
      final skyFg = ExcelColor.fromHexString('#0EA5E9');
      final amberFg = ExcelColor.fromHexString('#D97706');
      final greenFg = ExcelColor.fromHexString('#059669');

      // ── Header Sekolah ───────────────────────────────────────────
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('E1'));
      final namaSekolahCell = sheet.cell(CellIndex.indexByString('A1'));
      namaSekolahCell.value = TextCellValue('SMK MITRA PERMATA');
      namaSekolahCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        fontColorHex: whiteFg,
        backgroundColorHex: navyBg,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      );

      sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('E2'));
      final subJudulCell = sheet.cell(CellIndex.indexByString('A2'));
      subJudulCell.value = TextCellValue('Rekap Nilai Tugas Harian');
      subJudulCell.cellStyle = CellStyle(
        fontSize: 11,
        fontColorHex: ExcelColor.fromHexString('#93C5FD'),
        backgroundColorHex: navyBg,
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
      );

      // Info Guru, Kelas, Mapel, Semester, Tahun Ajaran
      final infoData = [
        ['Nama Guru', namaGuru],
        ['NIP', nip.isEmpty ? '-' : nip],
        ['Kelas', namaKelas],
        ['Mata Pelajaran', namaMapel],
        ['Semester', 'Semester $semester  —  $tahunAjaran'],
      ];

      for (int i = 0; i < infoData.length; i++) {
        final row = i + 4;
        final rowBg = i % 2 == 0
            ? ExcelColor.fromHexString('#FFFFFF')
            : ExcelColor.fromHexString('#F8FAFC');

        final cellLabel = sheet.cell(CellIndex.indexByString('A$row'));
        cellLabel.value = TextCellValue(infoData[i][0]);
        cellLabel.cellStyle = CellStyle(
          fontSize: 11,
          fontColorHex: mutedFg,
          backgroundColorHex: rowBg,
        );

        sheet.merge(
          CellIndex.indexByString('B$row'),
          CellIndex.indexByString('E$row'),
        );
        final cellValue = sheet.cell(CellIndex.indexByString('B$row'));
        cellValue.value = TextCellValue(infoData[i][1]);
        cellValue.cellStyle = CellStyle(
          bold: true,
          fontSize: 11,
          fontColorHex: darkFg,
          backgroundColorHex: rowBg,
        );
      }

      // ── Label Tabel ───────────────────────────────────────────────
      sheet.merge(
        CellIndex.indexByString('A10'),
        CellIndex.indexByString('E10'),
      );
      final labelTabel = sheet.cell(CellIndex.indexByString('A10'));
      labelTabel.value = TextCellValue('DATA NILAI SISWA');
      labelTabel.cellStyle = CellStyle(
        bold: true,
        fontSize: 10,
        fontColorHex: mutedFg,
        backgroundColorHex: softBg,
        horizontalAlign: HorizontalAlign.Left,
      );

      // ── Header Tabel ──────────────────────────────────────────────
      final headers = [
        'No',
        'Nama Siswa',
        'Rata-rata Teori',
        'Rata-rata Praktikum',
        'Nilai Tugas Harian',
      ];
      final headerColors = [mutedFg, mutedFg, skyFg, amberFg, greenFg];

      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 10),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          fontSize: 11,
          fontColorHex: headerColors[i],
          backgroundColorHex: softBg,
          horizontalAlign: i == 1
              ? HorizontalAlign.Left
              : HorizontalAlign.Center,
        );
      }

      // ── Data Siswa ────────────────────────────────────────────────
      for (int i = 0; i < rekapList.length; i++) {
        final r = rekapList[i];
        final siswa = r['siswa'];
        final rowIndex = 11 + i;
        final nilaiAkhir = (r['nilai_akhir'] as num).toDouble();
        final rataMateri = (r['rata_materi'] as num).toDouble();
        final rataPraktikum = (r['rata_praktikum'] as num).toDouble();

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
          fontSize: 11,
          fontColorHex: mutedFg,
          backgroundColorHex: rowBg,
          horizontalAlign: HorizontalAlign.Center,
        );

        // Nama Siswa
        final cellNama = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
        );
        cellNama.value = TextCellValue(siswa['nama_siswa'] ?? '-');
        cellNama.cellStyle = CellStyle(
          fontSize: 11,
          fontColorHex: darkFg,
          backgroundColorHex: rowBg,
        );

        // Rata-rata Teori
        final cellTeori = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
        );
        cellTeori.value = DoubleCellValue(rataMateri);
        cellTeori.cellStyle = CellStyle(
          bold: true,
          fontSize: 11,
          fontColorHex: skyFg,
          backgroundColorHex: rowBg,
          horizontalAlign: HorizontalAlign.Center,
        );

        // Rata-rata Praktikum
        final cellPraktikum = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
        );
        cellPraktikum.value = DoubleCellValue(rataPraktikum);
        cellPraktikum.cellStyle = CellStyle(
          bold: true,
          fontSize: 11,
          fontColorHex: amberFg,
          backgroundColorHex: rowBg,
          horizontalAlign: HorizontalAlign.Center,
        );

        // Nilai Tugas Harian
        final cellAkhir = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
        );
        cellAkhir.value = DoubleCellValue(nilaiAkhir);
        cellAkhir.cellStyle = CellStyle(
          bold: true,
          fontSize: 11,
          fontColorHex: ExcelColor.fromHexString(nilaiColorHex),
          backgroundColorHex: rowBg,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // ── Footer ───────────────────────────────────────────────────
      final footerRow = 12 + rekapList.length;
      sheet.merge(
        CellIndex.indexByString('A$footerRow'),
        CellIndex.indexByString('C$footerRow'),
      );
      final footerLeft = sheet.cell(CellIndex.indexByString('A$footerRow'));
      footerLeft.value = TextCellValue('SMK Mitra Permata');
      footerLeft.cellStyle = CellStyle(
        fontSize: 10,
        fontColorHex: mutedFg,
        backgroundColorHex: softBg,
      );

      sheet.merge(
        CellIndex.indexByString('D$footerRow'),
        CellIndex.indexByString('E$footerRow'),
      );
      final footerRight = sheet.cell(CellIndex.indexByString('D$footerRow'));
      footerRight.value = TextCellValue(tahunAjaran);
      footerRight.cellStyle = CellStyle(
        fontSize: 10,
        fontColorHex: mutedFg,
        backgroundColorHex: softBg,
        horizontalAlign: HorizontalAlign.Right,
      );

      // ── Lebar Kolom ───────────────────────────────────────────────
      sheet.setColumnWidth(0, 6);
      sheet.setColumnWidth(1, 32);
      sheet.setColumnWidth(2, 20);
      sheet.setColumnWidth(3, 22);
      sheet.setColumnWidth(4, 20);

      // ── Row Height ────────────────────────────────────────────────
      sheet.setRowHeight(0, 28);
      sheet.setRowHeight(1, 18);

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
