import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RekapNilaiService {
  Future<String?> downloadRekapSiswa({
    required String namaSiswa,
    required String nis,
    required String namaKelas,
    required String namaMapel,
    required String semester,
    required String tahunAjaran,
    required double rataMateri,
    required double rataPraktikum,
    required double nilaiAkhir,
    required List<Map<String, dynamic>> historyNilai,
  }) async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) return null;
      }

      final excel = Excel.createExcel();
      final sheet = excel['Nilai Siswa'];

      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#0EA5E9'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      // ── Judul ──
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('E1'));
      final judulCell = sheet.cell(CellIndex.indexByString('A1'));
      judulCell.value = TextCellValue('LAPORAN NILAI SISWA');
      judulCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Informasi siswa di bawah judul
      final infoData = [
        ['Nama Siswa', namaSiswa],
        ['NIS', nis],
        ['Kelas', namaKelas],
        ['Mata Pelajaran', namaMapel],
        ['Semester', semester],
        ['Tahun Ajaran', tahunAjaran],
      ];

      for (int i = 0; i < infoData.length; i++) {
        final row = i + 2;
        sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(
          infoData[i][0],
        );
        sheet.cell(CellIndex.indexByString('A$row')).cellStyle = CellStyle(
          bold: true,
        );
        sheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue(
          ': ${infoData[i][1]}',
        );
      }

      // Ringkasan nilai mulai dari baris setelah info siswa
      final ringkasanRow = infoData.length + 3;

      sheet.merge(
        CellIndex.indexByString('A$ringkasanRow'),
        CellIndex.indexByString('E$ringkasanRow'),
      );
      sheet.cell(CellIndex.indexByString('A$ringkasanRow')).value =
          TextCellValue('RINGKASAN NILAI');
      sheet
          .cell(CellIndex.indexByString('A$ringkasanRow'))
          .cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#F0F9FF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      final ringkasanHeaderRow = ringkasanRow + 1;
      final ringkasanHeaders = [
        'Rata-rata Teori',
        'Rata-rata Praktikum',
        'Nilai Tugas',
        'Nilai Akhir (40%)',
      ];
      final ringkasanCols = ['A', 'B', 'C', 'D'];

      for (int i = 0; i < ringkasanHeaders.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByString('${ringkasanCols[i]}$ringkasanHeaderRow'),
        );
        cell.value = TextCellValue(ringkasanHeaders[i]);
        cell.cellStyle = headerStyle;
      }

      final nilaiTugas = (rataMateri * 0.30) + (rataPraktikum * 0.70);
      final ringkasanValueRow = ringkasanHeaderRow + 1;
      final ringkasanValues = [
        rataMateri,
        rataPraktikum,
        nilaiTugas,
        nilaiAkhir,
      ];

      String nilaiColorHex;
      if (nilaiAkhir >= 80) {
        nilaiColorHex = '#059669';
      } else if (nilaiAkhir >= 60) {
        nilaiColorHex = '#D97706';
      } else {
        nilaiColorHex = '#DC2626';
      }

      for (int i = 0; i < ringkasanValues.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByString('${ringkasanCols[i]}$ringkasanValueRow'),
        );
        cell.value = DoubleCellValue(ringkasanValues[i]);
        cell.cellStyle = CellStyle(
          bold: i == 3,
          fontColorHex: i == 3
              ? ExcelColor.fromHexString(nilaiColorHex)
              : ExcelColor.fromHexString('#1A1F36'),
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // Header history nilai
      final historyTitleRow = ringkasanValueRow + 2;

      sheet.merge(
        CellIndex.indexByString('A$historyTitleRow'),
        CellIndex.indexByString('E$historyTitleRow'),
      );
      sheet.cell(CellIndex.indexByString('A$historyTitleRow')).value =
          TextCellValue('HISTORY NILAI');
      sheet
          .cell(CellIndex.indexByString('A$historyTitleRow'))
          .cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#F0F9FF'),
        horizontalAlign: HorizontalAlign.Center,
      );

      final historyHeaderRow = historyTitleRow + 1;
      final historyHeaders = ['No', 'Judul Tugas', 'Tipe', 'Metode', 'Nilai'];
      final historyCols = ['A', 'B', 'C', 'D', 'E'];

      for (int i = 0; i < historyHeaders.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByString('${historyCols[i]}$historyHeaderRow'),
        );
        cell.value = TextCellValue(historyHeaders[i]);
        cell.cellStyle = headerStyle;
      }

      // Isi history nilai
      for (int i = 0; i < historyNilai.length; i++) {
        final item = historyNilai[i];
        final tugas = item['tugas'];
        final row = historyHeaderRow + i + 1;
        final nilai = (item['nilai'] as num).toDouble();
        final isPraktikum = tugas?['type_tugas'] == 'praktikum';

        final rowBg = i % 2 == 0
            ? ExcelColor.fromHexString('#FFFFFF')
            : ExcelColor.fromHexString('#F8FAFC');

        String itemNilaiColorHex;
        if (nilai >= 80) {
          itemNilaiColorHex = '#059669';
        } else if (nilai >= 60) {
          itemNilaiColorHex = '#D97706';
        } else {
          itemNilaiColorHex = '#DC2626';
        }

        // No
        sheet.cell(CellIndex.indexByString('A$row')).value = IntCellValue(
          i + 1,
        );
        sheet.cell(CellIndex.indexByString('A$row')).cellStyle = CellStyle(
          backgroundColorHex: rowBg,
          horizontalAlign: HorizontalAlign.Center,
        );

        // Judul tugas
        sheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue(
          tugas?['judul_tugas'] ?? '-',
        );
        sheet.cell(CellIndex.indexByString('B$row')).cellStyle = CellStyle(
          backgroundColorHex: rowBg,
        );

        // Tipe
        sheet.cell(CellIndex.indexByString('C$row')).value = TextCellValue(
          isPraktikum ? 'Praktikum' : 'Teori',
        );
        sheet.cell(CellIndex.indexByString('C$row')).cellStyle = CellStyle(
          backgroundColorHex: rowBg,
          fontColorHex: isPraktikum
              ? ExcelColor.fromHexString('#D97706')
              : ExcelColor.fromHexString('#0EA5E9'),
          horizontalAlign: HorizontalAlign.Center,
        );

        // Metode
        sheet.cell(CellIndex.indexByString('D$row')).value = TextCellValue(
          tugas?['metode'] == 'upload' ? 'Upload' : 'Manual',
        );
        sheet.cell(CellIndex.indexByString('D$row')).cellStyle = CellStyle(
          backgroundColorHex: rowBg,
          horizontalAlign: HorizontalAlign.Center,
        );

        // Nilai
        sheet.cell(CellIndex.indexByString('E$row')).value = DoubleCellValue(
          nilai,
        );
        sheet.cell(CellIndex.indexByString('E$row')).cellStyle = CellStyle(
          backgroundColorHex: rowBg,
          fontColorHex: ExcelColor.fromHexString(itemNilaiColorHex),
          bold: true,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // ── Lebar kolom ──
      sheet.setColumnWidth(0, 5);
      sheet.setColumnWidth(1, 35);
      sheet.setColumnWidth(2, 15);
      sheet.setColumnWidth(3, 12);
      sheet.setColumnWidth(4, 10);

      excel.delete('Sheet1');

      // ── Simpan file ──
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
          'nilai_${namaSiswa}_${namaMapel}_semester${semester}.xlsx'.replaceAll(
            ' ',
            '_',
          );

      final file = File('${dir!.path}/$fileName');
      await file.writeAsBytes(bytes);

      return file.path;
    } catch (e) {
      return null;
    }
  }
}
