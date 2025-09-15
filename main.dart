import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

void main() => runApp(CalculatorApp());

class CalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Calculator',
      theme: ThemeData.dark(),
      home: CalculatorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String expression = '';
  String result = '';
  bool showFractionResult = false;
  bool isDarkMode = true;
  List<String> history = [];
  bool isResultDisplayed = false;
  String lastAnswer = '';



  // Format namba kwenye expression
  String formatExpression(String exp) {
    return exp.replaceAllMapped(
      RegExp(r'\d+(\.\d+)?'),
          (match) {
        try {
          return NumberFormat('#,##0.########').format(double.parse(exp.toString()));
        } catch (e) {
          return match.group(0)!;
        }
      },
    );
  }

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'AC') {
        expression = '';
        result = '';
        isResultDisplayed = false;
      } else if (value == '=') {
        _calculateResult();
        isResultDisplayed = true;
      } else if (value == 'DEL') {
        if (expression.isNotEmpty) {
          expression = expression.substring(0, expression.length - 1);
        }
      }

      else if (value == 'ANS') {
        if (lastAnswer.isNotEmpty){
          expression += lastAnswer;
          isResultDisplayed = false;
        }
      }
      else {
        if (isResultDisplayed){
          expression = value;
          isResultDisplayed = false;
        } else{
          expression += value;
        }}
    });
  }

  String preprocessExpression(String exp) {
    exp = exp.replaceAllMapped(RegExp(r'(\d)\('), (match)
    => '${match[1]}*(');
    exp = exp.replaceAllMapped(RegExp(r'\)(\d)'), (match)
    => ')*${match[1]}');
    exp = exp.replaceAllMapped(RegExp(r'\)\('), (match)
    => ')*(');
    return exp;
  }

  void _calculateResult() {
    try {
      String finalExp = expression
          .replaceAll(',', '') // Ondoa comma kabla ya kuhesabu
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('√', 'sqrt')
          .replaceAll('−', '-')
          .replaceAll('%', '/100')
          .replaceAll('π', math.pi.toString())
          .replaceAll('e', math.e.toString());

      finalExp = preprocessExpression(finalExp);

      //To set factorial manually
      if (finalExp.contains('!')){
        finalExp = finalExp.replaceAllMapped(RegExp(r'(\d+)!'), (m) {
          int n = int.parse(m.group(1)!);
          int fact =1;
          for (int i = 1; i<= n; i++){
            fact *=i;
          }
          return fact.toString();
        });

      }


      else {
        finalExp = finalExp
            .replaceAllMapped(RegExp(r'In\(([^)]+)\)'), (m){
          final val = double.parse(m.group(1)!);
          return math.log(val).toString();})

            .replaceAllMapped(RegExp(r'log\(([^)]+)\)'), (m){
          final val = double.parse(m.group(1)!);
          return (math.log(val) / math.log(10)).toString();})

            .replaceAllMapped(RegExp(r'sin\(([^)]+)\)'), (m) {
          return 'sin(3.1415926535/180*(${m.group(1)}))';
        })
            .replaceAllMapped(RegExp(r'cos\(([^)]+)\)'), (m) {
          return 'cos(3.1415926535/180*(${m.group(1)}))';
        })
            .replaceAllMapped(RegExp(r'tan\(([^)]+)\)'), (m) {
          String angleStr = m[1]!;
          double angle = double.tryParse(angleStr) ??0;
          if ((angle - 90) % 180 == 0){
            throw Exception('Math Error');
          }
          return 'tan(($angle * 3.1415926535/180))';
        });
        if (expression.contains(RegExp(r'sin\([^)]*\)/cos\([^)]*\)'))) {
          final numMatch = RegExp(r'sin\([^)]*\)/cos\([^)]*\)').firstMatch(expression);
          if (numMatch != null){
            double angle1 = double.tryParse(numMatch.group(1)!) ?? 0;
            double angle2 = double.tryParse(numMatch.group(2)!) ?? 0;
            if(angle1 == angle2){
              double radians = angle1 * math.pi / 180;
              double cosVal = math.cos(radians);
              if(cosVal.abs() < 1e-10) {
                result = 'Math Error';
              }
            }
            return;
          }
        }
      }

      Parser p = Parser();
      Expression exp = p.parse(finalExp);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      if (showFractionResult) {
        result = _toFraction(eval);
      }

      else {
        result = NumberFormat('#,##0.########').format(double.parse(eval.toStringAsFixed(10)));
      }
      lastAnswer = result.replaceAll(',', '');

      history.add('$expression = $result');
      if (history.length > 10){
        history.removeAt(0);
      }

    } catch (e) {
      result = 'Math Error';
    }
  }

  String _toFraction(double value) {
    const int maxDenominator = 1000;
    int numerator = 1;
    int denominator = 1;
    double minDiff = double.infinity;

    for (int d = 1; d <= maxDenominator; d++) {
      int n = (value * d).round();
      double diff = (value - n / d).abs();
      if (diff < minDiff) {
        numerator = n;
        denominator = d;
        minDiff = diff;
      }
    }

    return '$numerator/$denominator';
  }

  void _toggleResultFormat() {
    setState(() {
      showFractionResult = !showFractionResult;
    });
    _calculateResult();
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }



  void _showCurrencyConverter() {
    String fromCurrency = 'USD';
    String toCurrency = 'TZS';
    String input = '';
    String output = '';

    Map<String, double> rates = {
      'USD': 1.0,
      'EUR': 0.92,
      'GBP': 0.79,
      'INR': 83.0,
      'KES': 130.0,
      'TZS': 2600.0,
    };

    void convert() {
      double value = double.tryParse(input) ?? 0;
      if (value == 0) {
        output = "0";
        return;
      }
      double inUSD = value / rates[fromCurrency]!;
      double result = inUSD * rates[toCurrency]!;
      NumberFormat formatter = NumberFormat('#,##0.##');
      output = formatter.format(result);

      setState(() {
        history.add("$value $fromCurrency = $output $toCurrency");
        if (history.length > 10) history.removeAt(0);
      });
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          final screenHeight = MediaQuery.of(context).size.height;
          final screenWidth = MediaQuery.of(context).size.width;

          return AlertDialog(
            title: Text('Currency Converter'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.6,
                maxWidth: screenWidth * 0.9,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: fromCurrency,
                            isExpanded: true,
                            items: rates.keys.map((cur) {
                              return DropdownMenuItem(value: cur, child: Text(cur));
                            }).toList(),
                            onChanged: (val) => setState(() => fromCurrency = val!),
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward),
                        SizedBox(width: 10),
                        Expanded(
                          child: DropdownButton<String>(
                            value: toCurrency,
                            isExpanded: true,
                            items: rates.keys.map((cur) {
                              return DropdownMenuItem(value: cur, child: Text(cur));
                            }).toList(),
                            onChanged: (val) => setState(() => toCurrency = val!),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    TextField(
                      decoration: InputDecoration(labelText: 'Enter amount'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => input = val,
                    ),
                    SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => convert());
                      },
                      child: Text('Convert'),
                    ),
                    if (output.isNotEmpty) ...[
                      SizedBox(height: 15),
                      Text(
                        "Result: $output $toCurrency",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }



  void _showMeasurementConverter() {
    String category = 'Length';
    String fromUnit = 'Meters';
    String toUnit = 'Kilometers';
    String input = '';
    String output = '';

    final unitCategories = {
      'Length': ['Meters', 'Kilometers', 'Centimeters', 'Miles', 'Feet', 'Inches'],
      'Weight': ['Kilograms', 'Grams', 'Pounds', 'Ounces'],
      'Temperature': ['Celsius', 'Fahrenheit', 'Kelvin'],
    };

    void convert() {
      double value = double.tryParse(input) ?? 0;
      double result = 0;

      if (category == 'Length') {
        Map<String, double> lengthUnits = {
          'Meters': 1,
          'Kilometers': 1000,
          'Centimeters': 0.01,
          'Miles': 1609.34,
          'Feet': 0.3048,
          'Inches': 0.0254,
        };
        result = value * lengthUnits[fromUnit]! / lengthUnits[toUnit]!;
      } else if (category == 'Weight') {
        Map<String, double> weightUnits = {
          'Kilograms': 1,
          'Grams': 0.001,
          'Pounds': 0.453592,
          'Ounces': 0.0283495,
        };
        result = value * weightUnits[fromUnit]! / weightUnits[toUnit]!;
      } else if (category == 'Temperature') {
        if (fromUnit == toUnit) result = value;
        else if (fromUnit == 'Celsius' && toUnit == 'Fahrenheit') result = (value * 9 / 5) + 32;
        else if (fromUnit == 'Celsius' && toUnit == 'Kelvin') result = value + 273.15;
        else if (fromUnit == 'Fahrenheit' && toUnit == 'Celsius') result = (value - 32) * 5 / 9;
        else if (fromUnit == 'Fahrenheit' && toUnit == 'Kelvin') result = (value - 32) * 5 / 9 + 273.15;
        else if (fromUnit == 'Kelvin' && toUnit == 'Celsius') result = value - 273.15;
        else if (fromUnit == 'Kelvin' && toUnit == 'Fahrenheit') result = (value - 273.15) * 9 / 5 + 32;
      }

      NumberFormat formatter = NumberFormat('#,##0.####');
      output = formatter.format(result);

      setState(() {
        history.add("$value $fromUnit = $output $toUnit");
        if (history.length > 10) history.removeAt(0);
      });
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          final screenHeight = MediaQuery.of(context).size.height;
          final screenWidth = MediaQuery.of(context).size.width;

          return AlertDialog(
            title: Text('Measurement Converter'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.6, // max 60% ya screen
                maxWidth: screenWidth * 0.9,   // max 90% ya width
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<String>(
                      value: category,
                      isExpanded: true,
                      items: unitCategories.keys.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          category = val!;
                          fromUnit = unitCategories[category]![0];
                          toUnit = unitCategories[category]![1];
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: fromUnit,
                            isExpanded: true,
                            items: unitCategories[category]!.map((unit) {
                              return DropdownMenuItem(value: unit, child: Text(unit));
                            }).toList(),
                            onChanged: (val) => setState(() => fromUnit = val!),
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward),
                        SizedBox(width: 10),
                        Expanded(
                          child: DropdownButton<String>(
                            value: toUnit,
                            isExpanded: true,
                            items: unitCategories[category]!.map((unit) {
                              return DropdownMenuItem(value: unit, child: Text(unit));
                            }).toList(),
                            onChanged: (val) => setState(() => toUnit = val!),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(labelText: 'Enter value'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => input = val,
                    ),
                    SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => convert());
                      },
                      child: Text('Convert'),
                    ),
                    if (output.isNotEmpty) ...[
                      SizedBox(height: 15),
                      Text(
                        "Result: $output $toUnit",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  void _showMenuOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.currency_exchange),
            title: Text('Currency Conversion'),
            onTap: () {
              Navigator.pop(context);
              _showCurrencyConverter();
            },
          ),
          ListTile(
            leading: Icon(Icons.straighten),
            title: Text('Measurement Conversion'),
            onTap: () {
              Navigator.pop(context);
              _showMeasurementConverter();
            },
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('View History'),
            onTap: () {
              Navigator.pop(context);
              _showHistory();
            },
          ),
          ListTile(
            leading: Icon(Icons.brightness_6),
            title: Text('Toggle Theme'),
            onTap: () {
              Navigator.pop(context);
              _toggleTheme();
            },
          ),
        ],
      ),
    );
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
      ),
    );
  }

  void _showHistory() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Calculation History'),
        content: Container(
          width: double.maxFinite,
          child: ListView(
            children: history.map((entry) {
              return ListTile(
                title: Text(entry),
                onTap: () { Navigator.pop(context);
                if (entry.contains("=")) {
                  final parts = entry.split("=");
                  setState(() {
                    expression = parts[0].trim();
                    result = parts[1].trim();
                  });
                }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = isDarkMode ? ThemeData.dark() : ThemeData.light();

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chillu_07 Calculator',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(Icons.menu),
              onPressed: _showMenuOptions,
            ),
          ],
        ),

        body: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.grey,
                    borderRadius:BorderRadius.circular(20) ),
                padding: EdgeInsets.all(16),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SingleChildScrollView(scrollDirection: Axis.horizontal,
                      reverse: true,
                      // Tumia formatExpression hapa
                      child: Text(formatExpression(expression),
                        style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,

                      child: Text(result,
                        style: TextStyle(
                            fontSize: 70, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow:  TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: Colors.cyan,),
            _buildButtonGrid(),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _toggleResultFormat,
              child: Text(
                'Result Format: ${showFractionResult ? "Fraction" : "Decimal"}',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 25),
                backgroundColor: Colors.blueGrey,
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonGrid() {
    final buttons = [
      ['sin(', 'cos(', 'tan(', '√(', '^'],
      ['7', '8', '9', '÷', '('],
      ['4', '5', '6', '×', ')'],
      ['1', '2', '3', '−', '!'],
      ['0', '.', '/', '+', '%'],
      ['log(', 'In(', 'e', 'π'],
      ['DEL', 'AC', 'ANS', '='],
    ];

    return Expanded(
      flex: 2,
      child:Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          children: buttons.map((row) {
            return Expanded(
              child: Row(
                children: row.map((btn) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ElevatedButton(
                        onPressed: () => _onButtonPressed(btn),

                        style: ElevatedButton.styleFrom(
                          backgroundColor: btn == '='
                              ? Colors.green
                              : btn == 'AC'
                              ? Colors.red
                              : btn == 'DEL'
                              ? Colors.redAccent
                              : btn == 'ANS'
                              ? Colors.blue
                              : null,
                        ),
                        child: FittedBox(fit: BoxFit.scaleDown,
                          child: Text(btn, style: TextStyle(fontSize: 30)),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
